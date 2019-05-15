module Autotune
  # Handle stuff around having clonable repo
  # Model must have the following fields:
  # - repo_url
  # - version
  # - config
  # - status
  # - slug
  module Repo
    extend ActiveSupport::Concern

    # Checks if we need to sync files for this repo. Should only be run in the
    # context of a job.
    # @return [Boolean] True if a sync is needed
    def needs_sync?
      repo = setup_shell
      return false if repo.exist? && version == repo.version
      true
    end

    # Sync files from a remote repo to the local file system. Should only be
    # run in the context of a job.
    # @param [Boolean] <update> Force an update from the remote repo url
    # @param [Autotune::User] <current_user> User account used to upload thumbnails
    # @return [Boolean] True if anything was updated
    def sync_from_remote(update: false, current_user: nil)
      raise 'Repo URL is missing' if repo_url.blank?

      repo = setup_shell

      if repo.exist?
        # The correct repo files are on disk.

        repo.branch_from_repo_url(repo_url)
        if update
          # Update the repo
          repo.update
          self.version = repo.version
        elsif status.in?(%w[built updated]) && version == repo.version
          return false # no syncing occurs
        elsif version.present?
          # we're not updating, but the repo is broken, so set it up
          repo.commit_hash_for_checkout = version
          repo.update
        else
          # Repo is broke and we don't have a version
          repo.update
          self.version = repo.version
        end
      else
        # Clone the repo
        repo.clone(repo_url)
        if version.present?
          repo.commit_hash_for_checkout = version
          repo.update
        else
          # Track the current commit version
          repo.update
          self.version = repo.version
        end
      end

      # Setup the environment
      repo.setup_environment

      # Load the config file into the DB
      new_config = repo.read BLUEPRINT_CONFIG_FILENAME
      if new_config.blank?
        model_name = self.class.model_name.human
        raise "Can't read '#{BLUEPRINT_CONFIG_FILENAME}' in #{model_name} '#{slug}'"
      else
        self.config = new_config
      end

      # Stash the thumbnail
      if config['thumbnail'].present? && repo.exist?(config['thumbnail'])
        deployer(:media, :user => current_user).deploy_file(working_dir, config['thumbnail'])
      end

      true
    end

    # Sync files from a local blueprint repo directory. Should only be run in
    # the context of a job.
    # @param [Boolean] <update> Force an update from the remote repo url
    # @return [Boolean] True if anything was updated
    def sync_from_blueprint(update: false)
      raise 'No related blueprint' unless defined?(blueprint) && blueprint.present?

      # Make sure the blueprint has a version
      raise "Can't sync repo from blueprint, missing version" if blueprint.version.blank?

      # Create a new repo object based on the blueprints working dir
      blueprint_dir = blueprint.setup_shell

      # Make sure the blueprint exists
      raise 'Missing files!' unless blueprint_dir.exist?

      # Create a new repo object based on the projects working dir
      project_dir = setup_shell

      # check if the directory already exists on disk, make sure it's updated,
      # or copy the code from the blueprint
      if project_dir.exist?
        if update || project_dir.version != blueprint_version
          # Update the project files. Because of issue #218, due to
          # some weirdness in git 1.7, we can't just update the repo.
          # We have to make a new copy.
          project_dir.rm
          blueprint_dir.copy_to(project_dir.working_dir)
        end
      else
        # Copy the blueprint to the project working dir.
        blueprint_dir.copy_to(project_dir.working_dir)
      end

      if blueprint_version.blank?
        # project version is blank, so we assume HEAD and save it now
        self.blueprint_version = project_dir.version
      elsif project_dir.version != blueprint_version
        # Checkout correct version and branch
        project_dir.commit_hash_for_checkout = blueprint_version
        project_dir.update
        # update the config
        self.blueprint_config = project_dir.read(BLUEPRINT_CONFIG_FILENAME)
      end

      # Make sure the environment is correct for this version
      project_dir.setup_environment

      true
    end
  end
end
