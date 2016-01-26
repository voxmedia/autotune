module Autotune
  class SyncThemeJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    def perform(theme, update: false)
      #TODO (Kavya): Flesh this out
      # stub implementation of the job
      theme.data = Theme.get_theme_data
      theme.status = "ready"
      theme.save!
    end
  end
end
