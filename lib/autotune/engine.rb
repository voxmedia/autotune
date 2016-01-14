module Autotune
  # Autotune rails app
  class Engine < ::Rails::Engine
    isolate_namespace Autotune

    # Make sure we load jbuilder for views
    require 'jbuilder'

    # Bootstrap for css
    require 'bootstrap-sass'
    require 'bootstrap3-datetimepicker-rails'

    require 'will_paginate'

    require 'active_job/chaining'
    require 'active_job/locking'
    require 'active_job/unique'
    require 'active_job/chain'

    initializer 'autotune.init', :before => :load_config_initializers do |app|
      app.config.assets.precompile += %w(
        autotune/favicon.ico autotune/at_placeholder.png)

      app.config.autotune = Config.new

      # Figure out where we project our blueprints
      app.config.autotune.working_dir = File.expand_path(
        ENV['WORKING_DIR'] || './working', Rails.root)

      app.config.autotune.build_environment = { 'ENV' => Rails.env }
      app.config.autotune.setup_environment = { 'ENV' => Rails.env }
      app.config.autotune.git_ssh = File.expand_path('../../../bin/git_ssh.sh', __FILE__)
      app.config.autotune.git_askpass = File.expand_path('../../../bin/git_ask_pass.sh', __FILE__)
      app.config.autotune.faq_url = 'http://voxmedia.helpscoutdocs.com/category/19-autotune'
      app.config.autotune.themes = { :generic => 'Generic' }
      app.config.autotune.force_google_auth = false

      if ENV['REDIS_URL']
        app.config.autotune.redis = Redis.new(:url => ENV['REDIS_URL'])
      end

      Autotune.deployment(
        :preview,
        :connect => "file://#{Rails.root.join('public', 'preview')}",
        :base_url => '/preview'
      )
      Autotune.deployment(
        :media,
        :connect => "file://#{Rails.root.join('public', 'media')}",
        :base_url => '/media'
      )
      Autotune.deployment(
        :publish,
        :connect => "file://#{Rails.root.join('public', 'publish')}",
        :base_url => '/publish'
      )
    end

    initializer 'autotune.init', :after => :load_config_initializers do |app|
      # make sure the generic theme is always enabled
      app.config.autotune.themes[:generic] = 'Generic'
    end
  end
end
