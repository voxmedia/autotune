require 'work_dir/base'

module WorkDir
  # Repo
  class Repo < Base
    def branch
      @branch ||= 'master'
    end
    attr_writer :branch

    def set_hash
      @set_hash ||= 'HEAD'
    end
    attr_writer :set_hash

    # def initial_branch
    #   /\w{40}/.match(branch) ? 'master' : branch
    # end

    # Update the repo on disk
    def update
      # working_dir do
      #   git 'checkout', '.'
      #   git 'clean', '-ffd'
      #   git 'checkout', initial_branch
      #   git 'pull', '--recurse-submodules=yes'
      #   git 'fetch', 'origin'
      #   git 'checkout', branch
      #   git 'submodule', 'update', '--init'
      #   git 'clean', '-ffd'
      # end
      puts "update, branch - #{branch}, version - #{version}, set_hash - #{set_hash}"
      working_dir do
        git 'checkout', '.'
        git 'clean', '-ffd'
        git 'checkout', branch
        git 'pull', '--recurse-submodules=yes'
        git 'fetch', 'origin'
        git 'checkout', set_hash
        git 'submodule', 'update', '--init'
        git 'clean', '-ffd'
      end
    end

    def switch(new_branch)
      self.branch = new_branch
      update
    end

    def set_branch(repo_url)
      if repo_url =~ /#\S+[^\/]/
        self.branch = repo_url.split('#')[1]
      else
        self.branch = 'master'
      end
    end

    # Clone a repo to disk from the url
    def clone(repo_url)
      FileUtils.mkdir_p(File.dirname(working_dir))
      git 'clone', '--recursive', repo_url.split('#')[0], working_dir
      self.set_branch(repo_url)
      update
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

    def checkout_version(version_hash)
      version = 'HEAD'
      working_dir do
        version = git 'checkout', version_hash || 'HEAD'
      end
    end

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

    def status
      working_dir do
        git 'status'
      end
    end

    private

    # run a git command
    def git(*args)
      cmd(*['git'] + args)
    end
  end
end
