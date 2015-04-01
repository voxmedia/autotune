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
      app.config.autotune.environment = {}
      app.config.autotune.preview = {
        :connect => "file://#{Rails.root.join('public', 'preview')}",
        :base_url => '/preview'
      }
      app.config.autotune.publish = {}
      app.config.autotune.git_ssh = File.expand_path('../../../bin/git_ssh.sh', __FILE__)
      app.config.autotune.git_askpass = File.expand_path('../../../bin/git_ask_pass.sh', __FILE__)

      Rails.application.config.assets.precompile += ['alpaca.css']
    end
  end
end
