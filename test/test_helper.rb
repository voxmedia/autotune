# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

if system('hash redis-server >/dev/null 2>&1') && ENV['REDIS_URL'].nil?
  puts 'Running a redis server at port 6789 for testing'
  # Run a redis server so we can test things
  ENV['REDIS_URL'] = 'redis://localhost:6789'
  redis_pid = Process.spawn('redis-server --port 6789 >/dev/null')
  at_exit { Process.kill 'INT', redis_pid }
elsif ENV['REDIS_URL']
  puts "Will use #{ENV['REDIS_URL']} for redis tests"
else
  puts "Can't find redis-server, will skip related tests"
end

# Setup the rails app in test/dummy in order to test the engine
require File.expand_path('../../test/dummy/config/environment.rb',  __FILE__)
ActiveRecord::Migrator.migrations_paths = [
  File.expand_path('../../test/dummy/db/migrate', __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path(
  '../../db/migrate', __FILE__)
require 'rails/test_help'

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
end

require 'autotune_test_helper'
