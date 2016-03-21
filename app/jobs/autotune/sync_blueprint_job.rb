require 'work_dir'

module Autotune
  # setup the blueprint
  class SyncBlueprintJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    # do the deed
    def perform(blueprint, status: nil, update: false, build_themes: false)
      # Create a new repo object based on the blueprints working dir
      repo = WorkDir.repo(blueprint.working_dir,
                          Rails.configuration.autotune.setup_environment)

      if repo.exist?
        if update
          # Update the repo
          repo.update
          # Track the current commit version
          blueprint.version = repo.version
        elsif blueprint.status.in?(%w(testing ready)) && blueprint.version == repo.version
          # if we're not updating, bail if we have the files
          return
        elsif !update
          # we're not updating, but the blueprint is broken, so set it up
          repo.branch = blueprint.version
          repo.update
        end
      else
        # Clone the repo
        repo.clone(blueprint.repo_url)
        if blueprint.version.present?
          repo.branch = blueprint.version
          repo.update
        else
          # Track the current commit version
          blueprint.version = repo.version
        end
      end

      # Setup the environment
      repo.setup_environment

      # Load the blueprint config file into the DB
      blueprint.config = repo.read BLUEPRINT_CONFIG_FILENAME
      if blueprint.config.nil?
        raise "Can't read '%s' in blueprint '%s'" % [
          BLUEPRINT_CONFIG_FILENAME, blueprint.slug]
      end

      # Stash the thumbnail
      if blueprint.config['thumbnail'] && repo.exist?(blueprint.config['thumbnail'])
        blueprint.deployer(:media).deploy_file(
          blueprint.working_dir,
          blueprint.config['thumbnail'])
      end

      if blueprint.config['preview_type'] == 'live' && blueprint.config['sample_data']
        repo = WorkDir.repo(blueprint.working_dir,
                            Rails.configuration.autotune.build_environment)
        if blueprint.config['themes'].blank?
          themes = Autotune.config.themes.keys
        else
          themes = blueprint.config['themes']
        end

        sample_data = repo.read(blueprint.config['sample_data'])
        sample_data.delete('base_url')
        sample_data.delete('asset_base_url')

        # don't build a copy for each theme every time a project is updated
        if build_themes
          themes.each do |theme|
            slug = [blueprint.version, theme].join('-')
            # Use this as dummy build data for the moment
            build_data = sample_data.merge(
              'title' => blueprint.title,
              'slug' => slug,
              'theme' => theme)

            # Get the deployer object
            # probably don't want this to always be preview
            deployer = Autotune.new_deployer(
              :media, blueprint, :extra_slug => slug)

            # Run the before build deployer hook
            deployer.before_build(build_data, repo.env)

            # Run the build
            repo.working_dir do
              repo.cmd(
                BLUEPRINT_BUILD_COMMAND,
                :stdin_data => build_data.to_json)
            end

            # Upload build
            deployer.deploy(blueprint.full_deploy_dir)
          end
        end
      end

      # Blueprint is now ready for testing
      if status
        blueprint.status = status
      elsif blueprint.status != 'ready'
        blueprint.status = 'testing'
      end
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      blueprint.status = 'broken'
      raise
    ensure
      blueprint.save!
    end
  end
end
