# Job that updates the snapshot
class SyncBuildJob < ActiveJob::Base
  queue_as :default

  def perform(build)
    build.snapshot.sync(build.blueprint.repo)
    build.update(
      :status => 'updated', :blueprint_version => build.blueprint.repo.version)
  end
end
