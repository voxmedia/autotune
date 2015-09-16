require 'tmpdir'
require 'fileutils'

# put omniauth into test mode
OmniAuth.config.test_mode = true
OmniAuth.config.add_mock(:developer, OmniAuth::AuthHash.new(
  :provider => 'developer',
  :uid => 'test@example.com',
  :info => { :name => 'test', :email => 'test@example.com' }
))

# Reset themes for testing
Rails.configuration.autotune.themes = { :vox => 'Vox', :generic => 'Generic' }

# Display work_dir commands
# require 'work_dir'
# WorkDir.logger.level = Logger::DEBUG

# Add more helper methods to be used by all tests here...
class ActiveSupport::TestCase
  def setup
    # Make some temporary working dirs
    Rails.configuration.autotune.working_dir = File.expand_path(
      "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/")
    # puts 'Working dir: ' + Rails.configuration.autotune.working_dir
    FileUtils.mkdir_p(Rails.configuration.autotune.working_dir)
  end

  def teardown
    FileUtils.rm_rf(Rails.configuration.autotune.working_dir) \
      if File.exist?(Rails.configuration.autotune.working_dir)
    %w(preview publish media).each do |dir|
      FileUtils.rm_rf(Rails.root.join 'public', dir) \
        if File.exist?(Rails.root.join 'public', dir)
    end
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
