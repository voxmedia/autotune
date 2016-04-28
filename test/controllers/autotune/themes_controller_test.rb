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
      assert_equal Theme.all.count, decoded_response.length
    end

    test 'list themes as designer' do
      accept_json!
      valid_auth_header! :designer
      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Theme.all.count, decoded_response.length
    end

    test 'list themes as group designer' do
      accept_json!
      valid_auth_header! :group1_designer
      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Theme.where(:group => autotune_groups(:group1)).count, decoded_response.length
    end

    test 'list themes as author not allowed' do
      accept_json!
      valid_auth_header! :author
      get :index
      assert_response :forbidden
    end

    test 'show theme as superuser' do
      accept_json!
      valid_auth_header! :developer

      get :show, :id => autotune_themes(:theme1).id
      assert_response :success
      assert_equal autotune_themes(:theme1).id, decoded_response['id']
      assert_theme_data! default_theme_data
    end

    test 'show theme as designer' do
      accept_json!
      valid_auth_header! :designer

      get :show, :id => autotune_themes(:theme1).id
      assert_response :success
      assert_equal autotune_themes(:theme1).id, decoded_response['id']
      assert_theme_data! default_theme_data
    end

    test 'show theme as group designer' do
      accept_json!
      valid_auth_header! :group1_designer

      get :show, :id => autotune_themes(:theme1).id
      assert_response :success
      assert_equal autotune_themes(:theme1).id, decoded_response['id']
      assert_theme_data! default_theme_data
    end

    test 'show theme as author not allowed' do
      accept_json!
      valid_auth_header! :author
      get :show, :id => autotune_themes(:theme1).id
      assert_response :forbidden
    end

    test 'show theme as group designer not allowed' do
      accept_json!
      valid_auth_header! :group1_designer
      get :show, :id => autotune_themes(:theme2).id
      assert_response :forbidden
    end

    test 'show non-existent theme' do
      accept_json!
      valid_auth_header!

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, :id => 'foobar'
      end
    end

    test 'create theme' do
      accept_json!
      valid_auth_header!

      post :create, new_theme_data

      assert_response :created, decoded_response['error']
      assert_theme_data! new_theme_data

      # TODO: Update this to deal with themed blueprints
    end

    private

    def assert_theme_data! (data)
      assert_data_values data, data.keys
    end

    def default_theme_data
      @default_theme_data ||= {
        :title => 'Theme 1',
        :slug => 'theme1',
        :group_id => autotune_groups(:group1).id,
        :data => {},
        :parent_id => nil,
        :status =>'ready',
        :group_name =>autotune_groups(:group1).name,
        :merged_data =>  Rails.configuration.autotune.generic_theme
      }
    end

    def new_theme_data
      @new_theme_data ||= {
        :title => 'New Theme',
        :slug => 'newtheme',
        :group_id => autotune_groups(:group2).id,
        :data => {},
        :parent_id => nil,
        :status =>'ready',
        :group_name =>autotune_groups(:group2).name,
        :merged_data =>  Rails.configuration.autotune.generic_theme
      }
    end
  end
end
