require 'autoshell'
require 'date'
require 'logger'
require 'stringio'

module Autotune
  # project a blueprint
  class ProjectJob < ActiveJob::Base
    queue_as :default

    def perform(project, update: false, target: :preview, current_user: nil)
      if unique_lock?
        logger.debug("Cancel perform; Existing unique #{unique_lock_key}")
        return
      elsif project.file_lock?
        logger.debug("Retry job in 10s; Can't obtain lock #{project.file_lock_key}")
        return retry_job :wait => 10
      end

      unique_lock!
      project.file_lock!

      project.update!(:status => 'building')

      # Make sure we have the files we need to build
      if project.bespoke?
        project.sync_from_remote(:update => update, :current_user => current_user)
      else
        # make sure blueprint is synced before syncing from it
        if project.blueprint.needs_sync?
          if project.blueprint.file_lock?
            # if the blueprint needs sync but is currently locked, clear our
            # project file lock and retry the entire job
            project.file_unlock!
            return retry_job :wait => 10
          end
          project.blueprint.with_file_lock do |bp|
            bp.sync_from_remote(:current_user => current_user)
            bp.save!
          end
        end

        project.sync_from_blueprint(:update => update)
      end

      # make sure we have our arguments properly set
      target = target.to_sym
      current_user ||= project.user

      # Reset any previous error messages:
      project.meta.delete('error_message')

      # Create a new repo object based on the projects working dir
      repo = project.build_shell

      # Make sure the repo exists and is up to date (if necessary)
      raise 'Missing files!' unless repo.exist?

      # Add a few extras to the build data
      build_data = project.data.deep_dup
      build_data['build_type'] = 'publish'

      # Get the deployer object
      deployer = project.deployer(target, :user => current_user)

      # Run the before build deployer hook
      deployer.before_build(build_data, repo.env)

      # Run the build
      repo.cd { |s| s.run(BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json) }

      # Upload build
      deployer.deploy(project.full_deploy_dir)

      # Create screenshots (has to happen after upload)
      if deployer.take_screenshots?
        begin
          url = deployer.url_for('/')
          script_path = Autotune.root.join('bin', 'screenshot.js').to_s
          repo.cd(project.deploy_dir) { |s| s.run 'phantomjs', script_path, get_full_url(url) }

          # Upload screens
          repo.glob(File.join(project.deploy_dir, 'screenshots/*')).each do |file_path|
            deployer.deploy_file(project.full_deploy_dir, "screenshots/#{File.basename(file_path)}")
          end
        rescue Autoshell::CommandError => exc
          logger.error(exc.message)
          project.output_logger.warn(exc.message)
        end
      end

      # Set status and save project
      project.update_published_at = true if target == :publish
      project.status = 'built'
      project.output = project.dump_output_logger!
    rescue => exc
      project.output = project.dump_output_logger!
      # If the command failed, raise a red flag
      msg = \
        if exc.is_a? Autoshell::CommandError
          exc.message
        else
          exc.message + "\n" + exc.backtrace.join("\n")
        end
      project.output += "\n#{msg}"
      project.status = 'broken'
      raise
    ensure
      # Always make sure to release the file lock and save the project
      unique_unlock!
      project.file_unlock!
      project.save!
    end

    private

    def get_full_url(url)
      return url if url.start_with?('http')
      url.start_with?('//') ? 'http:' + url : 'http://localhost:3000' + url
    end

    def unique_lock_key
      return @unique_lock_key if defined?(@unique_lock_key) && @unique_lock_key.present?

      deserialize_arguments_if_needed
      @unique_lock_key ||= "unique:#{Digest::SHA1.hexdigest(serialize_arguments(arguments).to_s)}"
    end

    def unique_lock!
      raise "Can't obtain unique lock #{unique_lock_key}" if unique_lock?
      logger.debug "Obtained unique lock #{unique_lock_key}"
      Rails.cache.write(unique_lock_key, job_id)
    end

    def unique_lock?
      Rails.cache.exist?(unique_lock_key)
    end

    def unique_unlock!
      logger.debug "Released unique lock #{unique_lock_key}"
      Rails.cache.delete(unique_lock_key)
    end
  end
end
