require 'logger'
require 'work_dir/base'
require 'work_dir/repo'
require 'work_dir/website'

# Top-level module for work dir
module WorkDir
  # These vars are allowed to leak through to commands run in the working dir
  ALLOWED_ENV = %w(
    PATH LANG USER LOGNAME LC_CTYPE SHELL LD_LIBRARY_PATH ARCHFLAGS TMPDIR
    SSH_AUTH_SOCK HOME)

  BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'
  BLUEPRINT_BUILD_COMMAND = './autotune-build'

  class CommandError < StandardError; end

  class << self
    def logger
      return @logger unless @logger.nil?
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger.formatter = proc { |_lvl, _dt, _name, msg| "#{msg}\n" }
      @logger
    end
    attr_writer :logger

    def new(*args)
      Base.new(*args)
    end

    def repo(*args)
      Repo.new(*args)
    end

    def website(*args)
      Website.new(*args)
    end
  end
end
