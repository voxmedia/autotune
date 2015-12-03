require 'work_dir'

module Autotune
  # setup the blueprint
  class SyncBlueprintJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    # do the deed
    def perform(blueprint, status: nil, update: false)
      # Create a new repo object based on the blueprints working dir
      repo = WorkDir.repo(blueprint.working_dir,
                          Rails.configuration.autotune.setup_environment)

      if repo.exist?
        if update
          # Update the repo
          repo.update
        elsif blueprint.status.in?(%w(testing ready))
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
      end

      # Setup the environment
      repo.setup_environment

      # Load the blueprint config file into the DB
      blueprint.config = repo.read BLUEPRINT_CONFIG_FILENAME
      if blueprint.config.nil?
        raise "Can't read '%s' in blueprint '%s'" % [
          BLUEPRINT_CONFIG_FILENAME, blueprint.slug]
      end

      # Track the current commit version
      blueprint.version = repo.version

      # Stash the thumbnail
      if blueprint.config['thumbnail'] && repo.exist?(blueprint.config['thumbnail'])
        deployer = Autotune.new_deployer(:media, blueprint)
        deployer.deploy_file(
          blueprint.working_dir,
          blueprint.config['thumbnail'])
      end

      # Blueprint is now ready for testing
      if status
        blueprint.status = status
      elsif blueprint.status != 'ready'
        blueprint.status = 'testing'
      end
      blueprint.save!

      if blueprint.config['preview_type'] == 'live' && blueprint.config['sample_data']

        # would be nice to see how far in deploying

        blueprint.config['themes'].each do |theme|
          project_demo = blueprint.deep_dup
          project_demo['slug'] = [blueprint.slug, blueprint.version, theme].join('/')
          # Use this as dummy build data for the moment
          build_data = repo.read(blueprint.config['sample_data'])
          build_data.delete('base_url')
          build_data.update(
            'title' => project_demo.title,
            'slug' => project_demo.slug,
            'theme' => theme)

            # 'slug' => 'custom-' + blueprint.slug + '-' + blueprint.version,

          # Get the deployer object
          # probably don't want this to always be preview
          out = StringIO.new
          outlogger = Logger.new out
          deployer = Autotune.new_deployer(
            :preview, project_demo, :logger => outlogger)

          # Run the before build deployer hook
          deployer.before_build(build_data, repo.env)

          # Result of this is that the blueprint slug ends up being included along with the project slug, which isn't right
          # I wonder if you do a deep_dup of a blueprint to a project - maybe that would work
          # build_data['base_url'] = build_data['base_url'] + '/' + build_data['slug']
          # build_data['asset_base_url'] = build_data['asset_base_url'] + '/' + build_data['slug']

          # Run the build
          repo.working_dir do
            outlogger.info(repo.cmd(
              BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json))
          end

          # Upload build
          deployer.deploy(blueprint.full_deploy_dir)
          puts 'test.apps.voxmedia.com/at-preview/' + build_data['slug']
        end

      end

    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      blueprint.update!(:status => 'broken')
      raise
    end
  end
end
