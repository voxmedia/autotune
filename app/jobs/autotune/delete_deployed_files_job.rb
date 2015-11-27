require 'work_dir'

module Autotune
  # recursively delete a filepath
  class DeleteDeployedFilesJob < ActiveJob::Base
    queue_as :default

    # Delete deployed files.
    #
    # We can't just pass in the active model as an argument because it will
    # no longer exist in the database when this job runs. We need to have the
    # model class and the serialized data of the deployable object.
    def perform(klass, deployable_json, renamed: false)
      deployable = klass.constantize.new
      deployable.from_json(deployable_json)
      %w(media preview publish).each do |target|
        deployable.deployer(target).delete!(:renamed => renamed)
      end
    rescue
      retry_job
    end
  end
end
