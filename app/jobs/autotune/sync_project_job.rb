require 'work_dir'

module Autotune
  # Job that updates the snapshot
  class SyncProjectJob < ActiveJob::Base
    queue_as :default

    def perform(project)
      # Create a new snapshot object based on the projects working dir
      snapshot = WorkDir.snapshot(project.working_dir,
                                  Rails.configuration.autotune.environment)
      # Create a new repo object based on the blueprints working dir
      repo = WorkDir.repo(project.blueprint.working_dir,
                          Rails.configuration.autotune.environment)
      # rsync the files from the cloned repo to our snapshot folder
      snapshot.sync(repo)
      # Save the results
      project.update(
        :status => 'updated',
        :blueprint_version => project.blueprint.version)
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      project.update!(:status => 'broken')
      raise
    end
  end
end
