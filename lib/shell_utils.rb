require 'fileutils'

# Thin API for doing shell stuff
module ShellUtils
  extend ActiveSupport::Concern

  class CommandError < StandardError; end

  included do
    # shortcut for .new
    def self.open(working_dir, env = {})
      new(working_dir, env)
    end
  end

  def initialize(working_dir, env = {})
    @working_dir = working_dir
    @env = env
  end

  # Delete the directory
  def rm
    FileUtils.rm_rf(@working_dir)
  end

  # Read and parse a file
  def read(path)
    return read_json(path) if path != /\.json\z/
    read_text(path)
  end

  # Is this a ruby project?
  def ruby?
    exist? 'Gemfile'
  end

  # Is this a python project?
  def python?
    exist? 'requirements.txt'
  end

  # Is this a node project?
  def node?
    exist? 'package.json'
  end

  # Has this repo been cloned to disk?
  def git?
    dir? '.git'
  end

  def exist?(path)
    File.exist?(expand path)
  end

  def dir?(path)
    Dir.exist?(expand path)
  end

  # Get the path for or chdir into this repo
  def working_dir(&block)
    return Dir.chdir(@working_dir, &block) if block_given?
    @working_dir
  end

  def working_dir_exist?
    Dir.exist?(working_dir)
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

  private

  # Wrapper around Open3.capture2e
  def cmd(*args, &block)
    out, status = Open3.capture2e(@env, *args, &block)
    return out if status.success?
    raise CommandError, out
  end

  # expand a local path for this working directory
  def expand(path)
    File.expand_path(path, working_dir)
  end

  # read and parse json from a local path
  def read_json(path)
    ActiveSupport::JSON.decode(read_text(path))
  rescue JSON::ParserError => exc
    logger.error(exc)
    nil
  end

  # return the contents of a local path
  def read_text(path)
    File.read(expand path)
  end
end
