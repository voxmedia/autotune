# setup the blueprint
class InstallBlueprintJob < ActiveJob::Base
  queue_as :default

  def perform(blueprint)
    raise 'Blueprint already installed' if blueprint.installed?
    blueprint.install!
  end
end
