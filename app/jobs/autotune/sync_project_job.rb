require 'work_dir'

module Autotune
  # Job that updates the snapshot
  class SyncProjectJob < ActiveJob::Base
    queue_as :default

    def perform(project)
      # Create a new repo object based on the blueprints working dir
      repo = WorkDir.repo(project.blueprint.working_dir,
                          Rails.configuration.autotune.setup_environment)

      # Make sure the blueprint exists
      SyncBlueprintJob.perform_now(project.blueprint) unless repo.exist?

      # Create a new snapshot object based on the projects working dir
      snapshot = WorkDir.snapshot(project.working_dir,
                                  Rails.configuration.autotune.setup_environment)

      # use git archive to export a specific version to our snapshot
      repo.export_to(snapshot, project.blueprint_version)

      # Make sure the environment is setup
      snapshot.setup_environment

      # update the status
      project.update!(:status => 'updated')
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      project.update!(:status => 'broken')
      raise
    end
  end
end
