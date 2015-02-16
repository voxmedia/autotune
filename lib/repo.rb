require 'fileutils'

BLUEPRINT_BUILD_COMMAND = './autotune-build'
BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'

# Repo
class Repo
  class CommandError < StandardError; end

  # Create a new repo object from an existing repo
  def self.open(working_dir, env = {})
    new(working_dir, env)
  end

  # Create a new repo object from a newly cloned repo
  def self.clone(repo_url, working_dir, env = {})
    r = new(working_dir, env)
    r.clone(repo_url)
    r
  end

  def initialize(working_dir, env = {})
    @working_dir = working_dir
    @env = env
    @branch = 'master'
  end

  # Run the blueprint build command with the supplied data
  def build(data)
    working_dir do
      cmd(BLUEPRINT_BUILD_COMMAND, :stdin_data => data.to_json)
    end
  end

  # Update the repo on disk
  def update
    working_dir do
      git 'fetch', 'origin'
      git 'checkout', @branch
      git 'reset', '--hard', "origin/#{@branch}"
      git 'submodule', 'update', '--init'
    end
  end

  # Clone a repo to disk from the url
  def clone(repo_url)
    git 'clone', '--recursive', repo_url, @working_dir
  end

  # Delete the downloaded repo
  def rm
    FileUtils.rm_rf(@working_dir)
  end

  # Detect and setup the environment
  def setup_environment
    return setup_ruby_environment if ruby?
    return setup_python_environment if python?
    return setup_node_environment if node?
  end

  # Setup a ruby environment
  def setup_ruby_environment
    working_dir do
      bundle_install = %w(bundle install)
      if Rails.production?
        bundle_install += ['--path', "#{@working_dir}/.bundle", '--deployment']
      end
      cmd(*bundle_install)
    end
  end

  # Setup a python environment
  def setup_python_environment
    working_dir do
      cmd 'virtualenv', '.virtualenv'
      cmd '.virtualenv/bin/pip', '-r', 'requirements.txt'
    end
  end

  # Setup a node environment
  def setup_node_environment; end

  # Get the config data from this repo
  def config
    working_dir do
      File.open(BLUEPRINT_CONFIG_FILENAME) do |f|
        return ActiveSupport::JSON.decode(f.read)
      end
    end
    nil
  rescue JSON::ParserError => exc
    logger.error(exc)
    nil
  end

  # Get the current commit hash
  def commit_hash(branch_or_tag = nil)
    git 'rev-parse', branch_or_tag || 'HEAD'
  end
  alias_method :version, :commit_hash

  # Get the path for or chdir into this repo
  def working_dir(&block)
    return Dir.chdir(@working_dir, &block) if block_given?
    @working_dir
  end

  # Is this a ruby project?
  def ruby?
    File.exist?(File.join(@working_dir, 'Gemfile'))
  end

  # Is this a python project?
  def python?
    File.exist?(File.join(@working_dir, 'requirements.txt'))
  end

  # Is this a node project?
  def node?
    File.exist?(File.join(@working_dir, 'package.json'))
  end

  # Has this repo been cloned to disk?
  def cloned?
    Dir.exist?(File.join(@working_dir, '.git'))
  end

  private

  # Wrapper around Open3.capture2e
  def cmd(*args, &block)
    out, status = Open3.capture2e(@env, *args, &block)
    return out if status.success?
    raise CommandError, out
  end

  # run a git command
  def git(*args)
    cmd(*['git'] + args)
  end
end
