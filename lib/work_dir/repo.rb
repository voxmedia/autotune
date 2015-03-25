require 'work_dir/base'

module WorkDir
  # Repo
  class Repo < Base
    def branch
      @branch ||= 'master'
    end
    attr_writer :branch

    # Update the repo on disk
    def update
      working_dir do
        git 'fetch', 'origin'
        git 'checkout', branch
        git 'reset', '--hard', "origin/#{branch}"
        git 'submodule', 'update', '--init'
      end
    end

    # Checkout a different branch
    def switch(new_branch)
      self.branch = new_branch
      update
    end

    # Clone a repo to disk from the url
    def clone(repo_url)
      FileUtils.mkdir_p(File.dirname(working_dir))
      git 'clone', '--recursive', repo_url, working_dir
    end

    # Get the config data from this repo
    def config
      read WorkDir::BLUEPRINT_CONFIG_FILENAME
    end

    # Get the current commit hash
    def commit_hash(branch_or_tag = nil)
      git 'rev-parse', branch_or_tag || 'HEAD'
    end
    alias_method :version, :commit_hash

    private

    # run a git command
    def git(*args)
      cmd(*['git'] + args)
    end
  end
end
