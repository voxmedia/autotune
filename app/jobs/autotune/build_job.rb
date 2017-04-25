require 'autoshell'
require 'date'
require 'logger'
require 'stringio'

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    unique_job :ttl => 20.seconds, :with => :payload

    def perform(project, target: 'preview', current_user: nil)
      # Setup a new logger that logs to a string. The resulting log will
      # be saved to the output field of the project.
      out = StringIO.new
      outlogger = Logger.new out
      outlogger.formatter = proc do |severity, datetime, _progname, msg|
        "#{datetime.strftime('%b %e %H:%M %Z')}\t#{severity}\t#{msg}\n"
      end

      # Reset any previous error messages:
      project.meta.delete('error_message')

      # Create a new repo object based on the projects working dir
      repo = Autoshell.new(project.working_dir,
                           :env => Rails.configuration.autotune.build_environment,
                           :logger => outlogger)

      # Make sure the repo exists and is up to date (if necessary)
      raise 'Missing files!' unless repo.exist?

      # Add a few extras to the build data
      build_data = project.data.deep_dup
      build_data['build_type'] = 'publish'

      current_user ||= project.user

      # Get the deployer object
      deployer = Autotune.new_deployer(
        target.to_sym, project, :logger => outlogger)

      # Run the before build deployer hook
      deployer.before_build(build_data, repo.env, current_user)

      # Run the build
      repo.cd { |s| s.run(BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json) }

      # Upload build
      deployer.deploy(project.full_deploy_dir)

      # Create screenshots (has to happen after upload)
      if repo.command?('phantomjs') && !Rails.env.test?
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
          outlogger.warn(exc.message)
        end
      end

      # Set status and save project
      project.published_at = DateTime.current if target.to_sym == :publish
      project.status = 'built'
    rescue => exc
      # If the command failed, raise a red flag
      if exc.is_a? Autoshell::CommandError
        msg = exc.message
      else
        msg = exc.message + "\n" + exc.backtrace.join("\n")
      end
      logger.error(msg)
      outlogger.error(msg)
      project.status = 'broken'
      raise
    ensure
      # Always make sure to save the log and the project
      outlogger.close
      project.output = out.try(:string)
      project.save!
    end

    private

    def get_full_url(url)
      return url if url.start_with?('http')
      url.start_with?('//') ? 'http:' + url : 'http://localhost:3000' + url
    end
  end
end
