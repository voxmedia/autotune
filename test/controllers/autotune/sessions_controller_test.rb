require 'test_helper'

module Autotune
  # Test sessions controller
  class SessionsControllerTest < ActionController::TestCase
    test 'login' do
      get :new
      assert_response :success
    end

    test 'invalid auth' do
      @request.env['omniauth.auth'] = mock_auth[:invalid_credentials]
      assert_raises ArgumentError do
        get :create, :provider => 'developer'
      end
    end

    test 'login with preferred provider' do
      provider = Rails.configuration.omniauth_preferred_provider
      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_redirected_to root_path

      u = autotune_users(:developer)
      u.reload

      assert_equal 1, u.authorizations.length, 'Should be one auth'
    end

    test 'login with secondary provider' do
      skip unless OmniAuth.strategies.include?(OmniAuth::Strategies::GoogleOauth2)
      @request.env['omniauth.auth'] = mock_auth[:google_oauth2]
      get :create, :provider => 'google_oauth2'
      assert_response :bad_request
    end

    test 'add secondary provider' do
      skip unless OmniAuth.strategies.include?(OmniAuth::Strategies::GoogleOauth2)

      provider = Rails.configuration.omniauth_preferred_provider
      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_redirected_to root_path

      @request.env['omniauth.auth'] = mock_auth[:google_oauth2]
      get :create, :provider => 'google_oauth2'
      assert_redirected_to root_path

      u = autotune_users(:developer)
      u.reload

      assert_equal 2, u.authorizations.length, 'Should be two auths'
    end

    test 'add preferred provider' do
      provider = Rails.configuration.omniauth_preferred_provider
      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_redirected_to root_path

      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_response :bad_request

      u = autotune_users(:developer)
      u.reload

      assert_equal 1, u.authorizations.length, 'Should be one auth'
    end

    test 'login with used preferred provider' do

    end
  end
end
