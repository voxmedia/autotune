module Autotune
  class SyncThemeJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    def perform(theme)
      external_data = get_theme_data(theme)
      theme.data = external_data unless external_data.nil?
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
      Autotune.configuration.generic_theme
    end
  end
end
