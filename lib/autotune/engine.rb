module Autotune
  # Autotune rails app
  class Engine < ::Rails::Engine
    isolate_namespace Autotune

    # Make sure we load jbuilder for views
    require 'jbuilder'

    # Bootstrap for css
    require 'bootstrap-sass'

    initializer 'autotune.init', :before => :load_config_initializers do |app|
      app.config.autotune = Config.new
      # Figure out where we project our blueprints
      app.config.autotune.working_dir = File.expand_path(
        ENV['WORKING_DIR'] || './working', Rails.root)
      app.config.autotune.build_environment = { 'ENV' => Rails.env }
      app.config.autotune.setup_environment = { 'ENV' => Rails.env }
      app.config.autotune.preview = {
        :connect => "file://#{Rails.root.join('public', 'preview')}",
        :base_url => '/preview'
      }
      app.config.autotune.media = {
        :connect => "file://#{Rails.root.join('public', 'media')}",
        :base_url => '/media'
      }
      app.config.autotune.publish = {
        :connect => "file://#{Rails.root.join('public', 'publish')}",
        :base_url => '/publish'
      }
      app.config.autotune.git_ssh = File.expand_path('../../../bin/git_ssh.sh', __FILE__)
      app.config.autotune.git_askpass = File.expand_path('../../../bin/git_ask_pass.sh', __FILE__)
      app.config.autotune.faq_url = 'http://voxmedia.helpscoutdocs.com/category/19-autotune'
      app.config.autotune.themes = { :generic => 'Generic' }
    end

    initializer 'autotune.init', :after => :load_config_initializers do |app|
      # make sure the generic theme is always enabled
      app.config.autotune.themes[:generic] = 'Generic'
    end
  end
end
