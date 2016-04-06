require 'tmpdir'
require 'fileutils'

# put omniauth into test mode
OmniAuth.config.test_mode = true
OmniAuth.config.add_mock(:developer, OmniAuth::AuthHash.new(
  'provider' => 'developer',
  'uid' => 'test@example.com',
  'info' => { :name => 'test', :email => 'test@example.com' }
))
OmniAuth.config.add_mock(:google_oauth2, OmniAuth::AuthHash.new(
  :provider => 'google_oauth2',
  :uid => '123456789',
  :info => {
    :name => 'John Doe',
    :email => 'john@company_name.com',
    :first_name => 'John',
    :last_name => 'Doe',
    :image => 'https://lh3.googleusercontent.com/url/photo.jpg'
  },
  :credentials => {
    :token => 'token',
    :refresh_token => 'another_token',
    :expires_at => 1354920555,
    :expires => true
  },
  :extra => {
    :raw_info => {
      :sub => '123456789',
      :email => 'user@domain.example.com',
      :email_verified => true,
      :name => 'John Doe',
      :given_name => 'John',
      :family_name => 'Doe',
      :profile => 'https://plus.google.com/123456789',
      :picture => 'https://lh3.googleusercontent.com/url/photo.jpg',
      :gender => 'male',
      :birthday => '0000-06-25',
      :locale => 'en',
      :hd => 'company_name.com'
    },
    :id_info => {
      'iss' => 'accounts.google.com',
      'at_hash' => 'HK6E_P6Dh8Y93mRNtsDB1Q',
      'email_verified' => 'true',
      'sub' => '10769150350006150715113082367',
      'azp' => 'APP_ID',
      'email' => 'jsmith@example.com',
      'aud' => 'APP_ID',
      'iat' => 1353601026,
      'exp' => 1353604926,
      'openid_id' => 'https://www.google.com/accounts/o8/id?id=ABCdfdswawerSDFDsfdsfdfjdsf'
    }
  }
))

# Reset themes for testing
Rails.configuration.autotune.generic_theme = {
  'primary-color' => '#292929',
  'secondary-color' => '#e6e6e6',

  'twitter-handle' => '@testhandle'
}

# Display work_dir commands
# require 'work_dir'
# WorkDir.logger.level = Logger::DEBUG

# Add more helper methods to be used by all tests here...
class ActiveSupport::TestCase
  include ActiveJob::TestHelper

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

    assert_no_enqueued_jobs
  end

  def mock_auth
    OmniAuth.config.mock_auth
  end

  def repo_url
    File.expand_path('../repos/autotune-example-blueprint.git', __FILE__).to_s
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
