module Autotune
  # Job that updates the snapshot
  class SyncProjectJob < ActiveJob::Base
    queue_as :default

    def perform(project)
      project.snapshot.sync(project.blueprint.repo)
      project.update(
        :status => 'updated', :blueprint_version => project.blueprint.repo.version)
    end
  end
end
