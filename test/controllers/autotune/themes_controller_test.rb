require 'test_helper'

module Autotune
  class ThemesControllerTest < ActionController::TestCase
    fixtures 'autotune/themes', 'autotune/users', 'autotune/groups', 'autotune/group_memberships'
    test 'listing themes requires authentication' do
      accept_json!

      get :index
      assert_response :unauthorized
      assert_equal({ 'error' => 'Unauthorized' }, decoded_response)
    end

    test 'list themes as superuser' do
      accept_json!
      valid_auth_header! :developer

      valid_auth_header! :developer
      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal 2, decoded_response.length
    end

    test 'list themes as designer' do
      accept_json!
      valid_auth_header! :designer
      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal 2, decoded_response.length
    end
  end
end
