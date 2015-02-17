ENV['RAILS_ENV'] ||= 'test'

# Set the working dir to a temp location
require 'fileutils'
ENV['WORKING_DIR'] = './tmp/working'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

OmniAuth.config.test_mode = true
OmniAuth.config.add_mock(:developer, OmniAuth::AuthHash.new(
  :provider => 'developer',
  :uid => 'test@example.com',
  :info => { :name => 'test', :email => 'test@example.com' }
))

# Add more helper methods to be used by all tests here...
class ActiveSupport::TestCase
  def mock_auth
    OmniAuth.config.mock_auth
  end

  def repo_url
    'https://github.com/ryanmark/autotune-example-blueprint.git'
  end
end

# Helpers for controller tests
class ActionController::TestCase
  def valid_auth(provider = :developer)
    @request.env['omniauth.auth'] = mock_auth[provider]
  end

  def no_auth
    @request.env['omniauth.auth'] = nil
  end

  def invalid_auth
    @request.env['omniauth.auth'] = :invalid_credentials
  end
end
