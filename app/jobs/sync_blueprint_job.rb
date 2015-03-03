# setup the blueprint
class SyncBlueprintJob < ActiveJob::Base
  queue_as :default

  # do the deed
  def perform(blueprint)
    if blueprint.repo.exist?
      # Update the repo
      blueprint.sync_repo
    else
      # Clone the repo
      blueprint.create_repo
    end

    # Setup the environment
    blueprint.repo.setup_environment

    # Load the blueprint config file into the DB
    blueprint.config = blueprint.repo.config

    # look in the config for stuff like descriptions, sample images, tags
    blueprint.config['tags'].each do |t|
      tag = Tag.find_or_create_by(:title => t)
      blueprint.tags << tag unless blueprint.tags.include?(tag)
    end

    # Blueprint is now ready for testing
    blueprint.status = 'testing'
    blueprint.save!
  rescue WorkDir::CommandError => exc
    logger.error(exc)
    blueprint.update!(:status => 'broken')
    raise
  end
end
