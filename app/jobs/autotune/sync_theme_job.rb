module Autotune
  class SyncThemeJob < ActiveJob::Base
    # Job to reset theme data from an external source
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    def perform(theme, build_blueprints: true, current_user: nil)
      # get external data only for default themes
      if theme.is_default? && Rails.configuration.autotune.get_theme_data.is_a?(Proc)
        external_data = Rails.configuration.autotune.get_theme_data.call(theme)
      end
      theme.data = external_data unless external_data.nil?
      theme.status = 'ready'
      theme.save!

      # Queue blueprint rebuild if the theme saved successfully
      Blueprint.rebuild_themed_blueprints(current_user) if build_blueprints
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      theme.update!(:status => 'broken')
      raise
    end
  end
end
