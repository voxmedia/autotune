# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

# Setup the rails app in test/dummy in order to test the engine
require File.expand_path('../../test/dummy/config/environment.rb',  __FILE__)
ActiveRecord::Migrator.migrations_paths = [
  File.expand_path('../../test/dummy/db/migrate', __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path(
  '../../db/migrate', __FILE__)
require 'rails/test_help'

# put omniauth into test mode
OmniAuth.config.test_mode = true
OmniAuth.config.add_mock(:developer, OmniAuth::AuthHash.new(
  :provider => 'developer',
  :uid => 'test@example.com',
  :info => { :name => 'test', :email => 'test@example.com' }
))

# Make some temporary working dirs
require 'tmpdir'
require 'fileutils'
Rails.configuration.autotune.working_dir = File.expand_path(
  "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/")
# puts 'Working dir: ' + Rails.configuration.autotune.working_dir

# Add another theme for testing
Rails.configuration.autotune.themes['vox'] = 'Vox'

# Display work_dir commands
# require 'work_dir'
# WorkDir.logger.level = Logger::DEBUG

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
end

# Add more helper methods to be used by all tests here...
class ActiveSupport::TestCase
  def setup
    FileUtils.mkdir_p(Rails.configuration.autotune.working_dir)
  end

  def teardown
    FileUtils.rm_rf(Rails.configuration.autotune.working_dir) \
      if File.exist?(Rails.configuration.autotune.working_dir)
    FileUtils.rm_rf(Rails.root.join 'public', 'preview') \
      if File.exist?(Rails.root.join 'public', 'preview')
    FileUtils.rm_rf(Rails.root.join 'public', 'media') \
      if File.exist?(Rails.root.join 'public', 'media')
  end

  def mock_auth
    OmniAuth.config.mock_auth
  end

  def repo_url
    'https://github.com/voxmedia/autotune-example-blueprint.git'
  end
end

# Helpers for controller tests
class ActionController::TestCase
  fixtures 'autotune/users'

  setup do
    @routes = Autotune::Engine.routes
  end

  def valid_auth_header!(user = :developer)
    @request.headers['Authorization'] = "API-KEY auth=#{autotune_users(user).api_key}"
  end

  def accept_json!
    @request.headers['Accept'] = 'application/json'
  end

  def decoded_response
    ActiveSupport::JSON.decode(@response.body)
  end

  # Take an array of keys and assert that those keys exist in decoded_response
  def assert_data(*args)
    assert_keys decoded_response, *args
  end

  # Take a hash and an array of keys and assert that those keys exist
  def assert_keys(data, *args)
    assert_instance_of Hash, data
    keys = args.first.is_a?(Array) ? args.first : args
    keys.each do |k|
      assert decoded_response.key?(k.to_sym) || decoded_response.key?(k.to_s), "Should have #{k}"
    end
  end
end
