module Autotune
  class SyncThemeJob < ActiveJob::Base
    # Job to reset theme data from an external source
    queue_as :default

    def perform(theme, build_blueprints: true, current_user: nil)
      Autotune.lock!("theme:#{theme.id}") do |have_lock|
        return retry_job :wait => 10 unless have_lock

        # get external data only for default themes
        if theme.is_default? && Rails.configuration.autotune.get_theme_data.is_a?(Proc)
          external_data = Rails.configuration.autotune.get_theme_data.call(theme)
        end
        theme.data = external_data unless external_data.nil?
        theme.status = 'ready'
        theme.save!

        # Queue blueprint rebuild if the theme saved successfully
        Blueprint.rebuild_themed_blueprints(current_user) if build_blueprints
      end
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      theme.update!(:status => 'broken')
      raise
    end
  end
end
