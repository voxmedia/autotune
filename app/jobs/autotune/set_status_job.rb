module Autotune
  # project a blueprint
  class SetStatusJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    unique_job :with => :payload

    def perform(model_with_status, status)
      model_with_status.update(:status => status)
    end
  end
end
