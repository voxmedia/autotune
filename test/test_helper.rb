ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

OmniAuth.config.test_mode = true
OmniAuth.config.add_mock(:developer, OmniAuth::AuthHash.new(
  :provider => 'developer',
  :uid => 'test@example.com',
  :info => { :name => 'test', :email => 'test@example.com' }
))

# Make some temporary working dirs
require 'tmpdir'
require 'fileutils'
Rails.configuration.working_dir = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
Rails.configuration.blueprints_dir = File.join(Rails.configuration.working_dir, 'blueprints')
Rails.configuration.builds_dir = File.join(Rails.configuration.working_dir, 'builds')

# Add more helper methods to be used by all tests here...
class ActiveSupport::TestCase
  def setup
    [:working_dir, :blueprints_dir, :builds_dir].each do |s|
      Dir.mkdir(Rails.configuration.try(s)) unless Dir.exist?(Rails.configuration.try(s))
    end
  end

  def teardown
    FileUtils.rm_rf(Rails.configuration.working_dir) if File.exist?(Rails.configuration.working_dir)
  end

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
