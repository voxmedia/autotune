require 'autoshell'

module Autotune
  # recursively delete a filepath
  class MoveWorkDirJob < ActiveJob::Base
    queue_as :default

    # do the deed
    def perform(path, new_path)
      # Get a generic workdir object for the path
      wd = Autoshell.new(path)
      wd.move_to(new_path) if wd.exist?
    end
  end
end
