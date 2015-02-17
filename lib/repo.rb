require 'fileutils'

BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'

# Repo
class Repo
  include ShellUtils

  def branch
    @branch ||= 'master'
  end
  attr_writer :branch

  # Create a new repo object from a newly cloned repo
  def self.clone(repo_url, working_dir, env = {})
    r = new(working_dir, env)
    r.clone(repo_url)
    r
  end

  # Update the repo on disk
  def update
    working_dir do
      git 'fetch', 'origin'
      git 'checkout', branch
      git 'reset', '--hard', "origin/#{branch}"
      git 'submodule', 'update', '--init'
    end
  end

  # Clone a repo to disk from the url
  def clone(repo_url)
    git 'clone', '--recursive', repo_url, @working_dir
  end

  # Get the config data from this repo
  def config
    read BLUEPRINT_CONFIG_FILENAME
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
