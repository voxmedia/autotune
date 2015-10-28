require 'fileutils'
require 'mime/types'
require 'open3'

module WorkDir
  # Thin API for doing shell stuff
  class Base
    attr_writer :logger
    attr_accessor :env

    # Create a new shell object with a working directory and environment vars
    def initialize(path, env = {})
      @working_dir = path.to_s
      @env = ENV.select { |k, _| WorkDir::ALLOWED_ENV.include? k }
      @env['SHELL'] = '/bin/bash'
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

    def glob(pattern)
      working_dir do
        Dir.glob(pattern)
      end
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
        cmd 'bundle', 'install', '--path', '.bundle', '--deployment'
      end
    end

    # Setup a python environment
    def setup_python_environment
      return false unless python?
      working_dir do
        cmd 'virtualenv', '.virtualenv'
        cmd './.virtualenv/bin/pip', '-r', 'requirements.txt'
      end
    end

    # Setup a node environment
    def setup_node_environment
      return false unless node?
      working_dir do
        cmd 'npm', 'install'
      end
    end

    # Wrapper around Open3.capture2e
    def cmd(*args, **opts, &block)
      opts[:unsetenv_others] = true unless opts.keys.include? :unsetenv_others
      out, status = Open3.capture2e(@env, *args, **opts, &block)
      message = "#{Dir.pwd} $ #{args.join(' ')}\n#{out}"
      logger.debug(message)
      return out if status.success?
      raise CommandError, message
    end

    # expand a local path for this working directory
    def expand(path)
      File.expand_path(path, working_dir).to_s
    end

    # Delete a path in the working directory
    def rm(path)
      FileUtils.rm_rf(expand path)
    end

    # Copy a path from the working directory to another location
    def cp(path, dest)
      FileUtils.rm_rf(expand dest)
      if File.directory?(expand path)
        FileUtils.mkdir_p(expand dest)
        FileUtils.cp_r(expand(path), expand(dest))
      else
        FileUtils.mkdir_p(File.dirname(expand dest))
        FileUtils.cp(expand(path), expand(dest))
      end
    end

    # Return an array of filenames
    def ls
      Dir.entries(@working_dir)
    end

    # Move this working dir to another path
    def move_to(path)
      raise CommandError, 'Destination exists' if File.exist?(expand path)
      FileUtils.mkdir_p(File.dirname(expand path))
      FileUtils.mv(@working_dir, expand(path))
    end

    # Copy this working dir to another path
    def copy_to(path)
      raise CommandError, 'Destination exists' if File.exist?(expand path)
      FileUtils.mkdir_p(File.dirname(expand path))
      FileUtils.cp_r(@working_dir, expand(path))
    end

    # Delete the working directory
    def destroy
      FileUtils.rm_rf(@working_dir)
    end

    # Get mime for a file
    def mime(path)
      MIME::Types.type_for(expand path).first
    end

    # Read and parse a file
    def read(path)
      m = mime(path)
      return read_json(path) if m.content_type == 'application/json'
      return read_binary(path) if m.binary?
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

    # return the binary contents of a local path
    def read_binary(path)
      if exist? path
        File.binread(expand path)
      else
        nil
      end
    end

    def logger
      @logger ||= WorkDir.logger
    end

    def to_s
      @working_dir
    end
  end
end
