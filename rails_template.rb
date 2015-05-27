# Add gems
gem 'resque', '~> 1.25.2'
gem 'omniauth-github', '~> 1.1.2'
gem 'foreman', '~> 0.77.0'
gem 's3deploy', :git => 'https://github.com/ryanmark/s3deploy-ruby.git'
gem 'autotune', git: 'https://github.com/voxmedia/autotune', branch: 'master'

# Setup foreman
file 'Procfile', <<-CODE
redis: redis-server
resque_worker: bundle exec rake environment resque:work QUEUE=default
rails: bundle exec rails s
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

initializer 'autotune.rb', "require 'autotune'"

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
      cd my_project/
      bundle exec foreman start
  =======================================================
  SAY
end
