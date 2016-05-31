# Add gems
gem 'resque', '~> 1.25.2'
gem 'omniauth-github', '~> 1.1.2'
gem 'foreman', '~> 0.77.0'
gem 'unicorn-rails', '~> 2.2.0'
gem 's3deploy',
    :git => 'https://github.com/ryanmark/s3deploy-ruby.git'
gem 'autotune',
    :git => 'https://github.com/voxmedia/autotune.git'

# Setup foreman
file 'Procfile', <<-CODE
redis: redis-server
resque_worker: bundle exec rake environment resque:work QUEUE=default TERM_CHILD=1
rails: bundle exec unicorn_rails -p 3000 -c config/unicorn.rb
CODE

# Setup resque
append_file 'Rakefile', "require 'resque/tasks'"

application 'config.active_job.queue_adapter = :resque'

initializer 'resque.rb', <<-CODE
Resque.redis = ENV['REDIS_SERVER'] || 'localhost:6379'
Resque.redis.namespace =  ENV['REDIS_NAMESPACE'] || 'resque:AutoTune'
CODE

# Setup omniauth initializer
initializer 'omniauth.rb', <<-CODE
OmniAuth.config.logger = Rails.logger
Rails.configuration.omniauth_preferred_provider = Rails.env.production? ? :github : :developer
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
end
CODE

initializer 'autotune.rb', <<-CODE
# Be sure to restart your server when you modify this file.
Autotune.configure do |conf|
  # For notifications
  conf.redis = Redis.new(:host => ENV['REDIS_SERVER'])

  # Where should the `FAQ` link go?
  conf.faq_url = 'http://voxmedia.helpscoutdocs.com/category/19-autotune'

  # Environment variables used when building blueprints
  conf.build_environment = {
    # 'AWS_ACCESS_KEY_ID' => ENV['AWS_ACCESS_KEY_ID'],
    # 'AWS_SECRET_ACCESS_KEY' => ENV['AWS_SECRET_ACCESS_KEY'],

    # 'GOOGLE_OAUTH_PERSON' => ENV['GOOGLE_OAUTH_PERSON'],
    # 'GOOGLE_OAUTH_ISSUER' => ENV['GOOGLE_OAUTH_ISSUER'],
    # 'GOOGLE_OAUTH_KEYFILE' => ENV['GOOGLE_OAUTH_KEYFILE'],

    'ENV' => Rails.env
  }

  # These are the environment variables used during git operations
  conf.setup_environment = {
    'GIT_HTTP_USERNAME' => ENV['GIT_HTTP_USERNAME'],
    'GIT_HTTP_PASSWORD' => ENV['GIT_HTTP_PASSWORD'],
    'GIT_ASKPASS' => Rails.configuration.autotune.git_askpass,

    'GIT_PRIVATE_KEY' => ENV['GIT_PRIVATE_KEY'],
    'GIT_SSH' => Rails.configuration.autotune.git_ssh,

    'ENV' => Rails.env
  }

  # Theme meta data
  conf.theme_meta_data = {
    'colors' => {
      'primary_color' => {
        'friendly_name' => 'Primary color',
        'helper_text' => 'Dominant color for the theme'
      },
      'secondary_color' => {
        'friendly_name' => 'Secondary color',
        'helper_text' => 'Secondary color for the theme'
      },
      'button_bg_color' => {
        'friendly_name' => 'Button background color',
        'helper_text' => 'Color for buttons'
      },
      'button_bg_color_hover' => {
        'friendly_name' => 'Button background hover color',
        'helper_text' => 'Color for hover state of buttons'
      },
      'button_font_color' => {
        'friendly_name' => 'Button font color',
        'helper_text' => 'Color for text on buttons'
      }
    },
    'social' => {
      'twitter_handle' => {
        'friendly_name' => 'Twitter account',
        'helper_text' => 'Used for via @ text for shares'
      }
    }
  }

  # Generic theme data
  conf.generic_theme = {
    'colors' => {
      'primary_color' => ' #444444',
      'secondary_color' => ' #444444',
      'button_bg_color' => ' #444444',
      'button_bg_color_hover' => 'darken($button-bg-color, 4%)',
      'button_font_color' => 'white'

    },
    'fonts' => {
      'font_css' => '',
      'body_font_family' => 'Georgia Regular, serif',
      'header_font_family' => 'Georgia Bold, serif',
      'button_font_family' => 'Georgia Regular, serif',
      'header_font_weight' => 700,
      'button_font_weight' => 'normal'
    },
    'social' => {
      'twitter_handle' => 'voxmediainc'
    }
  }
end

# -------------------------------
# Deployment
# -------------------------------
# Autotune has deployment targets; preview, publish and media. New projects
# are always deployed to the preview target. Projects are deployed to the
# publish target when a user clicks the publish button. Media is used to store
# thumbnails and other things.

# # Deployment settings for production
# if Rails.env == 'production'
#   Autotune.deployment(
#     :preview,
#     :connect => 's3://apps.newsorg.com/at-preview',
#     :base_url => '//apps.newsorg.com/at-preview'
#   )
#   Autotune.deployment(
#     :publish,
#     :connect => 's3://apps.newsorg.com/at',
#     :base_url => '//apps.newsorg.com/at'
#   )
#   Autotune.deployment(
#     :media,
#     :connect => 's3://apps.newsorg.com/at-media',
#     :base_url => 'https://apps.newsorg.com/at-media'
#   )
# # Deployment settings for staging
# elsif Rails.env == 'staging'
#   Autotune.deployment(
#     :preview,
#     :connect => 's3://test.newsorg.com/at-preview',
#     :base_url => '//test.newsorg.com/at-preview'
#   )
#   Autotune.deployment(
#     :publish,
#     :connect => 's3://test.newsorg.com/at',
#     :base_url => '//test.newsorg.com/at'
#   )
#   Autotune.deployment(
#     :media,
#     :connect => 's3://test.newsorg.com/at-media',
#     :base_url => 'http://test.newsorg.com/at-media'
#   )
# end

# -------------------------------
# Authentication
# -------------------------------
# Auth is handled by a configurable callback you can define here. The
# callback is passed an omniauth object and can return different things
# depending on how you want auth to work. See the Wiki.

Autotune.config.verify_omniauth = lambda do |omniauth|
  Rails.logger.debug omniauth
  # give this user complete access
  return [:superuser] # or return true
  # refuse access to a user
  # return false
  # give designer access
  # return [:designer]
  # give editor access
  # return [:editor]
  # give author access
  # return [:author]
  # give designer access to specific themes
  # return :designer => ['My newsorg']
  # give author access to specific themes
  # return :author => ['My newsorg']
  # give editor access to specific themes
  # return :editor => ['My newsorg', 'Generic']
end

# -------------------------------
# Theme data customization
# -------------------------------
# Getting data for themes is defined as a callback here that you can customize
# It is recommended that you merge the final theme data with generic theme to
# make sure that all theme variables are available in all themes

Autotune.config.get_theme_data = lambda do |theme|
   Autotune.config.generic_theme
end
CODE

file 'config/unicorn.rb', <<-CODE
worker_processes 6
timeout 90
CODE

file 'config/theme_map.yml', <<-CODE
---
- name: Generic
  theme: generic
CODE

# add engine routes
route "mount Autotune::Engine => '/'"

# disable magic
run 'rm config/initializers/wrap_parameters.rb'

say "About to download stuff. It'll be a minute."

after_bundle do
  run 'bundle exec rake autotune:install:migrations'
  run 'bundle exec rake db:migrate'

  say <<-SAY
=======================================================
  Your new Autotune application is now ready to rock!
    cd #{app_path}
    bundle exec foreman start
=======================================================
  SAY
end
