require 'test_helper'

module Autotune
  # Test sessions controller
  class SessionsControllerTest < ActionController::TestCase
    fixtures 'autotune/users', 'autotune/authorizations'
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

    test 'login with existing preferred provider' do
      provider = Rails.configuration.omniauth_preferred_provider
      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_redirected_to root_path

      u = autotune_users(:developer)
      u.reload

      assert_equal 1, u.authorizations.length, 'Should be one auth'
    end

    test 'login with new preferred provider' do
      autotune_authorizations(:developer).destroy

      provider = Rails.configuration.omniauth_preferred_provider
      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_redirected_to root_path

      u = Autotune::Authorization.find_by_auth_hash(mock_auth[provider.to_sym]).user

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

      u = Autotune::Authorization.find_by_auth_hash(mock_auth[provider.to_sym]).user

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

      u = Autotune::Authorization.find_by_auth_hash(mock_auth[provider.to_sym]).user

      assert_equal 1, u.authorizations.length, 'Should be one auth'
    end

    test 'add used secondary provider' do
      provider = Rails.configuration.omniauth_preferred_provider
      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_redirected_to root_path

      @request.env['omniauth.auth'] = mock_auth[:google_oauth2]
      get :create, :provider => 'google_oauth2'
      assert_redirected_to root_path

      u = Autotune::Authorization.find_by_auth_hash(mock_auth[provider.to_sym]).user

      assert_equal 2, u.authorizations.length, 'Should be two auths'

      u = autotune_users :superuser
      @controller.current_user = u

      assert_equal u, @controller.current_user, 'Current user should be updated'

      @request.env['omniauth.auth'] = mock_auth[:google_oauth2]
      get :create, :provider => 'google_oauth2'
      assert_response :bad_request
    end

    test 'add secondary provider when we already have it' do
      provider = Rails.configuration.omniauth_preferred_provider
      @request.env['omniauth.auth'] = mock_auth[provider.to_sym]
      get :create, :provider => provider.to_s
      assert_redirected_to root_path

      @request.env['omniauth.auth'] = mock_auth[:google_oauth2]
      get :create, :provider => 'google_oauth2'
      assert_redirected_to root_path

      u = Autotune::Authorization.find_by_auth_hash(mock_auth[provider.to_sym]).user

      assert_equal 2, u.authorizations.length, 'Should be two auths'

      dupe_mock = mock_auth[:google_oauth2].dup
      dupe_mock[:uid] = '987654321'
      @request.env['omniauth.auth'] = dupe_mock
      get :create, :provider => 'google_oauth2'
      assert_response :bad_request
    end
  end
end
