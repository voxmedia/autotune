require 'test_helper'

# Test sessions controller
class SessionsControllerTest < ActionController::TestCase
  test 'login' do
    resp = get :new
    assert_equal 200, resp.status
  end

  test 'developer omniauth strategy' do
    valid_auth
    get :create, :provider => 'developer'
    assert_redirected_to root_path
    assert_equal "Welcome #{mock_auth[:developer][:info][:name]}!", flash[:notice]
  end

  test 'invalid auth' do
    invalid_auth
    assert_raises ArgumentError do
      get :create, :provider => 'developer'
    end
  end
end
