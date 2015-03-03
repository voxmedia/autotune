# delete the blueprint
class DestroyProjectJob < ActiveJob::Base
  queue_as :default

  # do the deed
  def perform(project)
    project.snapshot.destroy
  end
end
