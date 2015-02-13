require 'fileutils'

BLUEPRINT_BUILD_COMMAND = './autotune-build'
BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'

# Repo
class Repo
  class CommandError < StandardError; end

  def self.open(working_dir, env = {})
    new(working_dir, env)
  end

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

  def build(data)
    Dir.chdir(@working_dir) do
      cmd(BLUEPRINT_BUILD_COMMAND, :stdin_data => data.to_json)
    end
  end

  def update
    Dir.chdir(@working_dir) do
      git 'checkout', @branch
      git 'fetch', 'origin'
      git 'reset', '--hard', "origin/#{@branch}"
      git 'submodule', 'update', '--init'
    end
  end

  def clone(repo_url)
    git 'clone', '--recursive', repo_url, @working_dir
  end

  def rm
    FileUtils.rm_rf(@working_dir)
  end

  def setup_environment
    return setup_ruby_environment if ruby?
    return setup_python_environment if python?
    return setup_node_environment if node?
  end

  def setup_ruby_environment
    Dir.chdir(@working_dir) do
      bundle_install = %w(bundle install)
      if Rails.production?
        bundle_install += ['--path', "#{@working_dir}/.bundle", '--deployment']
      end
      cmd(*bundle_install)
    end
  end

  def setup_python_environment
    Dir.chdir(@working_dir) do
      cmd 'virtualenv', '.virtualenv'
      cmd '.virtualenv/bin/pip', '-r', 'requirements.txt'
    end
  end

  def setup_node_environment; end

  def config
    Dir.chdir(@working_dir) do
      File.open(BLUEPRINT_CONFIG_FILENAME) do |f|
        return ActiveSupport::JSON.decode(f.read)
      end
    end
    nil
  rescue JSON::ParserError => exc
    logger.error(exc)
    nil
  end

  def ruby?
    File.exist?(File.join(@working_dir, 'Gemfile'))
  end

  def python?
    File.exist?(File.join(@working_dir, 'requirements.txt'))
  end

  def node?
    File.exist?(File.join(@working_dir, 'package.json'))
  end

  def cloned?
    Dir.exist?(File.join(@working_dir, '.git'))
  end

  private

  def cmd(*args, &block)
    out, status = Open3.capture2e(@env, *args, &block)
    return out if status.success?
    raise CommandError, out
  end

  def git(*args)
    cmd(*['git'] + args)
  end
end
