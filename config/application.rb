require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Ground level module
module Autotune
  VERSION = '0.0.1'
  SLUG_OR_ID_REGEX = /([-\w]+|\d+)/

  # Autotune rails application
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Setup jobs
    config.active_job.queue_adapter = :resque

    # Autoload
    config.autoload_paths += %W(#{config.root}/lib)

    # Figure out where we project our blueprints
    config.working_dir = File.expand_path(ENV['WORKING_DIR'] || './working', Rails.root)
    config.blueprints_dir = File.join(config.working_dir, 'blueprints')
    config.projects_dir = File.join(config.working_dir, 'projects')
    [:working_dir, :blueprints_dir, :projects_dir].each do |s|
      Dir.mkdir(config.try(s)) unless Dir.exist?(config.try(s))
    end
  end
end
