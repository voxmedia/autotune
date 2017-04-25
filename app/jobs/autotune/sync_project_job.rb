require 'autoshell'

module Autotune
  # Job that updates the project working dir
  class SyncProjectJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    unique_job :ttl => 20.seconds, :with => :payload

    def perform(project, update: false)
      if project.bespoke?
        project.sync_from_repo(update: update)
      else
        # Make sure the blueprint has a version
        raise 'Missing blueprint version' if project.blueprint.version.blank?

        # Create a new repo object based on the blueprints working dir
        blueprint_dir = project.blueprint.setup_shell

        # Make sure the blueprint exists
        raise 'Missing files!' unless blueprint_dir.exist?

        # Create a new repo object based on the projects working dir
        project_dir = project.setup_shell

        if project_dir.exist?
          if update || project_dir.version != project.blueprint_version
            # Update the project files. Because of issue #218, due to
            # some weirdness in git 1.7, we can't just update the repo.
            # We have to make a new copy.
            project_dir.rm
            blueprint_dir.copy_to(project_dir.working_dir)
          elsif project_dir.version == project.blueprint_version
            # if we're not updating, bail if we have the files
            return
          end
        else
          # Copy the blueprint to the project working dir.
          blueprint_dir.copy_to(project_dir.working_dir)
        end

        if project.blueprint_version.blank?
          # project version is blank, so we assume HEAD and save it now
          project.blueprint_version = project_dir.version
        elsif project_dir.version != project.blueprint_version
          # Checkout correct version and branch
          project_dir.commit_hash_for_checkout = project.blueprint_version
          project_dir.update
          # Make sure the environment is correct for this version
          project_dir.setup_environment
          # update the config
          project.blueprint_config = project_dir.read(BLUEPRINT_CONFIG_FILENAME)
        end
      end

      # Project is now updated
      project.status = 'updated'
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      project.status = 'broken'
      raise
    ensure
      project.save!
    end
  end
end
