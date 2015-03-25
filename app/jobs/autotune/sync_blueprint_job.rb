require 'work_dir'

module Autotune
  # setup the blueprint
  class SyncBlueprintJob < ActiveJob::Base
    queue_as :default

    # do the deed
    def perform(blueprint)
      # Create a new repo object based on the blueprints working dir
      repo = WorkDir.repo(blueprint.working_dir,
                          Rails.configuration.autotune.environment)
      if repo.exist?
        # Update the repo
        repo.update
      else
        # Clone the repo
        repo.clone(blueprint.repo_url)
      end

      # Setup the environment
      repo.setup_environment

      # Load the blueprint config file into the DB
      blueprint.config = repo.config

      # look in the config for stuff like descriptions, sample images, tags
      blueprint.config['tags'].each do |t|
        tag = Tag.find_or_create_by(:title => t)
        blueprint.tags << tag unless blueprint.tags.include?(tag)
      end

      # Get the type from the config
      blueprint.type = blueprint.config['type'].downcase

      # Track the current commit version
      blueprint.version = repo.version

      # Blueprint is now ready for testing
      blueprint.status = 'testing'
      blueprint.save!
    rescue WorkDir::CommandError => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      blueprint.update!(:status => 'broken')
      raise
    end
  end
end
