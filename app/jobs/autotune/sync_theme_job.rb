module Autotune
  class SyncThemeJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    def perform(theme, update: false)
      #TODO (Kavya): Flesh this out
      # stub implementation of the job
      external_data = get_theme_data(theme)
      theme.data.deep_merge! external_data unless external_data.nil?
      theme.status = "ready"
      theme.save!
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      theme.update!(:status => 'broken')
      raise
    end

    # This can be overridden in the app to pull data from an external source
    def get_theme_data(theme)
      {:test => "something"}
    end
  end
end
