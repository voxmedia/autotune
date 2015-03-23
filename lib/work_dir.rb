require 'work_dir/base'
require 'work_dir/snapshot'
require 'work_dir/repo'

# Top-level module for work dir
module WorkDir
  # These vars are allowed to leak through to commands run in the working dir
  ALLOWED_ENV = %w(PATH LANG USER LOGNAME LC_CTYPE SHELL LD_LIBRARY_PATH ARCHFLAGS)

  BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'
  BLUEPRINT_BUILD_COMMAND = './autotune-build'

  class CommandError < StandardError; end

  def self.new(*args)
    Base.new(*args)
  end

  def self.snapshot(*args)
    Snapshot.new(*args)
  end

  def self.repo(*args)
    Repo.new(*args)
  end
end
