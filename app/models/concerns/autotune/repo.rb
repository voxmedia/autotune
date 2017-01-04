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

    # Sync files from a remote repo to the local file system. Should only be
    # run in the context of a job.
    # @param [Boolean] <update> Force an update from the remote repo url
    # @return [Boolean] True if anything was updated
    def sync_from_repo(update: false)
      raise 'Repo URL is missing' if repo_url.blank?

      repo = setup_shell

      if repo.exist?
        # The correct repo files are on disk.

        repo.branch_from_repo_url(repo_url)
        if update
          # Update the repo
          repo.update
          self.version = repo.version
        elsif status.in?(%w(built updated)) && version == repo.version
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
        raise "Can't read '%s' in %s '%s'" % [
          BLUEPRINT_CONFIG_FILENAME, self.class.model_name.human, slug]
      else
        self.config = new_config
      end

      # Stash the thumbnail
      if config['thumbnail'].present? && repo.exist?(config['thumbnail'])
        deployer(:media).deploy_file(working_dir, config['thumbnail'])
      end

      return true
    end
  end
end
