require 'work_dir'

module Autotune
  # Job that updates the project working dir
  class SyncProjectJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    def perform(project, update: false)
      # Create a new repo object based on the blueprints working dir
      blueprint_dir = WorkDir.repo(
        project.blueprint.working_dir,
        Rails.configuration.autotune.setup_environment)

      # Make sure the blueprint exists
      raise 'Missing files!' unless blueprint_dir.exist?

      # Create a new repo object based on the projects working dir
      project_dir = WorkDir.repo(
        project.working_dir,
        Rails.configuration.autotune.setup_environment)

      if project_dir.exist? && update
        # Update the project files. Because of issue #218, due to
        # some weirdness in git 1.7, we can't just update the repo.
        # We have to make a new copy.
        project_dir.destroy
        blueprint_dir.copy_to(project_dir.working_dir)
      elsif project_dir.exist?
        # if we're not updating, bail if we have the files
        return
      else
        # Copy the blueprint to the project working dir.
        blueprint_dir.copy_to(project_dir.working_dir)
      end

      if project_dir.commit_hash != project.blueprint_version
        # checkout the right git version
        project_dir.switch(project.blueprint_version)
        # Make sure the environment is correct for this version
        project_dir.setup_environment
        # update the status
        project.update!(
          :status => 'updated',
          :blueprint_config => project_dir.read(BLUEPRINT_CONFIG_FILENAME))
      else
        # update the status
        project.update!(:status => 'updated')
      end
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      project.update!(:status => 'broken')
      raise
    end
  end
end
