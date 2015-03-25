module Autotune
  # Autotune rails app
  class Engine < ::Rails::Engine
    isolate_namespace Autotune

    # Make sure we load jbuilder for views
    require 'jbuilder'

    initializer 'autotune.init', :before => :load_config_initializers do |app|
      app.config.autotune = Config.new
      # Figure out where we project our blueprints
      app.config.autotune.working_dir = File.expand_path(
        ENV['WORKING_DIR'] || './working', Rails.root)
      app.config.autotune.blueprints_dir = File.join(
        app.config.autotune.working_dir, 'blueprints')
      app.config.autotune.projects_dir = File.join(
        app.config.autotune.working_dir, 'projects')
      app.config.autotune.environment = {}
    end
  end
end
