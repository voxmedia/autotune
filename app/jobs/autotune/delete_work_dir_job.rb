module Autotune
  # recursively delete a filepath
  class DeleteWorkDirJob < ActiveJob::Base
    queue_as :default

    # do the deed
    def perform(path)
      wd = WorkDir.new(path)
      wd.destroy if wd.exist?
    end
  end
end
