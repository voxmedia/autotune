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

      puts 'repo', repo
      puts blueprint.working_dir
      puts Rails.configuration.autotune.setup_environment
      puts
      puts blueprint.as_json

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

      if blueprint.config['live_preview'] == 'live'
        # Use this as dummy build data for the moment
        build_data = {
          "title": "Timeline Test",
          "slug": "slug-test",
          "theme": "custom",
          "customColor": "#282828",
          "moments": [
            {
              "moment": "May 25, 1977",
              "headline": "Star Wars: A New Hope",
              "image": "http://imgc.allpostersimages.com/images/P-473-488-90/67/6751/7TAZ100Z/posters/star-wars-episode-iv-new-hope-classic-movie-poster.jpg",
              "text": "The Imperial Forces -- under orders from cruel Darth Vader (David Prowse) -- hold Princess Leia (Carrie Fisher) hostage, in their efforts to quell the rebellion against the Galactic Empire. Luke Skywalker (Mark Hamill) and Han Solo (Harrison Ford), captain of the Millennium Falcon, work together with the companionable droid duo R2-D2 (Kenny Baker) and C-3PO (Anthony Daniels) to rescue the beautiful princess, help the Rebel Alliance, and restore freedom and justice to the Galaxy."
            }
          ]
        }
        build_data.update(
          'title' => blueprint.title + ' demo',
          'slug' => blueprint.slug + '-' + blueprint.version,
          'theme' => 'custom')

        # Get the deployer object
        # probably don't want this to always be preview
        deployer = Autotune.new_deployer(
          :preview, blueprint, :logger => outlogger)

        # Run the before build deployer hook
        deployer.before_build(build_data, repo.env)

        # Run the build
        repo.working_dir do
          outlogger.info(repo.cmd(
            BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json))
        end

        # Upload build
        # this is missing something - not sure exactly what to pass in here
        deployer.deploy
      end

    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      blueprint.update!(:status => 'broken')
      raise
    end
  end
end
