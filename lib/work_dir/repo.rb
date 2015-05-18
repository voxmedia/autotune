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
        git 'checkout', working_dir
        git 'clean', '-fd'
        git 'checkout', 'master'
        git 'pull'
        git 'fetch', 'origin'
        git 'checkout', branch
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

    # Get the current commit hash
    def commit_hash(branch_or_tag = nil)
      version = 'HEAD'
      working_dir do
        version = git 'rev-parse', branch_or_tag || 'HEAD'
      end
      version.strip
    end
    alias_method :version, :commit_hash

    # Get a tar archive of the repo as a string
    def archive(branch_or_tag = nil)
      working_dir do
        git 'archive', branch_or_tag || 'HEAD', :binmode => true
      end
    end

    # Extract an archive to a destination working dir object
    def export_to(dest, branch_or_tag = nil)
      FileUtils.mkdir_p(dest.working_dir)
      dest.working_dir do
        cmd 'tar', '-x', :stdin_data => archive(branch_or_tag), :binmode => true
      end
    end

    private

    # run a git command
    def git(*args)
      cmd(*['git'] + args)
    end
  end
end
