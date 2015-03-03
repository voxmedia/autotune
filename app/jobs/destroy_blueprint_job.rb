# delete the blueprint
class DestroyBlueprintJob < ActiveJob::Base
  queue_as :default

  # do the deed
  def perform(blueprint)
    blueprint.repo.destroy
  end
end
