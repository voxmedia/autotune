require 'fileutils'

# These vars are allowed to leak through to commands run in the working dir
ALLOWED_ENV = %w(PATH LANG USER LOGNAME LC_CTYPE SHELL LD_LIBRARY_PATH ARCHFLAGS)

# Thin API for doing shell stuff
class WorkDir
  class CommandError < StandardError; end

  # Create a new shell object with a working directory and environment vars
  def initialize(working_dir, env = {})
    @working_dir = working_dir
    @env = ENV.select { |k, _| ALLOWED_ENV.include? k }
    @env.update env
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

  def exist?(path = '.')
    File.exist?(expand path)
  end

  def dir?(path = '.')
    Dir.exist?(expand path)
  end

  # Get the path for or chdir into this repo
  def working_dir(&block)
    return Dir.chdir(@working_dir, &block) if block_given?
    @working_dir
  end

  # Setup the environment
  def setup_environment
    setup_ruby_environment || setup_python_environment || setup_node_environment
  end

  # Do we have an environment setup?
  def environment?
    dir?('.bundle') || dir?('.virtualenv') || dir?('node_modules')
  end

  # Setup a ruby environment
  def setup_ruby_environment
    return false unless ruby?
    working_dir do
      cmd 'bundle', 'install', '--path', "#{working_dir}/.bundle", '--deployment'
    end
  end

  # Setup a python environment
  def setup_python_environment
    return false unless python?
    working_dir do
      cmd 'virtualenv', '.virtualenv'
      cmd '.virtualenv/bin/pip', '-r', 'requirements.txt'
    end
  end

  # Setup a node environment
  def setup_node_environment; end

  # Wrapper around Open3.capture2e
  def cmd(*args, **opts, &block)
    opts[:unsetenv_others] = true unless opts.keys.include? :unsetenv_others
    out, status = Open3.capture2e(@env, *args, **opts, &block)
    return out if status.success?
    raise CommandError, out
  end

  # expand a local path for this working directory
  def expand(path)
    File.expand_path(path, working_dir)
  end

  # Delete the working directory
  def rm
    FileUtils.rm_rf(@working_dir)
  end

  # Read and parse a file
  def read(path)
    return read_json(path) if path != /\.json\z/
    read_text(path)
  end

  # read and parse json from a local path
  def read_json(path)
    text = read_text(path)
    return nil if text.nil?
    ActiveSupport::JSON.decode(text)
  rescue JSON::ParserError
    nil
  end

  # return the contents of a local path
  def read_text(path)
    if exist? path
      File.read(expand path)
    else
      nil
    end
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
