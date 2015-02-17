# setup the blueprint
class InstallBlueprintJob < ActiveJob::Base
  queue_as :default

  def perform(blueprint)
    raise 'Blueprint already installed' if blueprint.installed?

    # Clone the repo, and setup the environment
    blueprint.repo.setup_environment

    # Load the blueprint config file into the DB
    blueprint.config = blueprint.repo.config

    # look in the config for stuff like descriptions, sample images, tags
    # TODO: load stuff from config

    # Blueprint is now ready for testing
    blueprint.status = 'testing'
    blueprint.save!
  rescue ShellUtils::CommandError => exc
    logger.error(exc)
    blueprint.update!(:status => 'broken')
    false
  end
end
