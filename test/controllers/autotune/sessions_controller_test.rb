require 'test_helper'

module Autotune
  # Test sessions controller
  class SessionsControllerTest < ActionController::TestCase
    test 'login' do
      get :new
      assert_response :success
    end

    test 'developer omniauth strategy' do
      @request.env['omniauth.auth'] = mock_auth[:developer]
      get :create, :provider => 'developer'
      assert_redirected_to root_path
    end

    test 'invalid auth' do
      @request.env['omniauth.auth'] = :invalid_credentials
      assert_raises ArgumentError do
        get :create, :provider => 'developer'
      end
    end
  end
end
