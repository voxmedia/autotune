# setup the blueprint
class InstallBlueprintJob < ActiveJob::Base
  queue_as :default

  # do the deed
  def perform(blueprint)
    raise 'Blueprint already installed' if blueprint.installed?

    # Clone the repo, and setup the environment
    blueprint.repo.setup_environment

    # Load the blueprint config file into the DB
    blueprint.config = blueprint.repo.config

    # look in the config for stuff like descriptions, sample images, tags
    # TODO: load stuff from config
    blueprint.config['tags'].each do |t|
      blueprint.tags << Tag.find_or_create_by(:title => t)
    end

    # Blueprint is now ready for testing
    blueprint.status = 'testing'
    blueprint.save!
  rescue WorkDir::CommandError => exc
    logger.error(exc)
    blueprint.update!(:status => 'broken')
    false
  end
end
