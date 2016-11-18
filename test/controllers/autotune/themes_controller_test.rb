require 'test_helper'

module Autotune
  class ThemesControllerTest < ActionController::TestCase
    fixtures 'autotune/themes', 'autotune/users',
             'autotune/groups', 'autotune/group_memberships'

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

      # TODO: Update this to deal with themed blueprints update jobs
    end

    test 'create theme as designer' do
      accept_json!
      valid_auth_header! :designer

      post :create, new_theme_data

      assert_response :created, decoded_response['error']
      assert_theme_data! new_theme_data

      # TODO: Update this to deal with themed blueprints update jobs
    end

    test 'create theme as group designer not allowed' do
      accept_json!
      valid_auth_header! :group1_designer

      post :create, new_theme_data

      assert_response :forbidden

      # TODO: Update this to deal with themed blueprints update jobs
    end

    test 'create theme as editor not allowed' do
      accept_json!
      valid_auth_header! :editor

      post :create, new_theme_data

      assert_response :forbidden
    end

    test 'create theme as author not allowed' do
      accept_json!
      valid_auth_header! :author

      post :create, new_theme_data

      assert_response :forbidden
    end

    test 'update theme' do
      accept_json!
      valid_auth_header!

      title = 'Updated theme 1'

      put(:update,
          :id => autotune_themes(:theme1).id,
          :title => title)


      assert_response :success, decoded_response['error']

      updated_theme = Theme.find decoded_response['id']
      assert_equal title, updated_theme.title
    end

    test 'update theme as designer' do
      accept_json!
      valid_auth_header! :designer

      title = 'Updated theme 1'

      put(:update,
          :id => autotune_themes(:theme1).id,
          :title => title)


      assert_response :success, decoded_response['error']

      updated_theme = Theme.find decoded_response['id']
      assert_equal title, updated_theme.title
    end

    test 'update theme as group designer' do
      accept_json!
      valid_auth_header! :group1_designer

      title = 'Updated theme 1'

      put(:update,
          :id => autotune_themes(:theme1).id,
          :title => title)


      assert_response :success, decoded_response['error']

      updated_theme = Theme.find decoded_response['id']
      assert_equal title, updated_theme.title
    end

    test 'update theme as group designer not allowed' do
      accept_json!
      valid_auth_header! :group1_designer

      title = 'Updated theme 2'

      put(:update,
          :id => autotune_themes(:theme2).id,
          :title => title)


      assert_response :forbidden
    end

    test 'update theme as author not allowed' do
      accept_json!
      valid_auth_header! :author

      title = 'Updated theme 1'

      put(:update,
          :id => autotune_themes(:theme1).id,
          :title => title)


      assert_response :forbidden
    end

    test 'delete theme' do
      accept_json!
      valid_auth_header!

      delete :destroy, :id => autotune_themes(:child_theme1).id
      assert_response :no_content
    end

    test 'delete theme as designer' do
      accept_json!
      valid_auth_header! :designer

      delete :destroy, :id => autotune_themes(:child_theme1).id
      assert_response :no_content
    end

    test 'delete theme as group designer' do
      accept_json!
      valid_auth_header! :group1_designer

      delete :destroy, :id => autotune_themes(:child_theme1).id
      assert_response :no_content
    end

    test 'delete theme as author not allowed' do
      accept_json!
      valid_auth_header! :author

      delete :destroy, :id => autotune_themes(:child_theme1).id
      assert_response :forbidden
    end

    test 'default theme can not be deleted' do
      accept_json!
      valid_auth_header!

      delete :destroy, :id => autotune_themes(:theme1).id
      assert_response :bad_request
    end

    test 'reset theme' do
      accept_json!
      valid_auth_header!

      data = {'test' => 'value'}

      put(:update,
          :id => autotune_themes(:theme1).id,
          :data => data)

      assert_response :success, decoded_response['error']

      updated_theme = Theme.find decoded_response['id']
      assert_equal data, updated_theme.data

      assert_performed_jobs 1 do
        put :reset, :id => autotune_themes(:theme1).id
      end

      assert_response :success, decoded_response['error']

      updated_theme.reload
      assert_equal RESET_THEME_DATA, updated_theme.data
    end

    test 'reset theme as designer' do
      accept_json!
      valid_auth_header! :designer

      data = {'test' => 'value'}

      put(:update,
          :id => autotune_themes(:theme1).id,
          :data => data)

      assert_response :success, decoded_response['error']

      updated_theme = Theme.find decoded_response['id']
      assert_equal data, updated_theme.data

      assert_performed_jobs 1 do
        put :reset, :id => autotune_themes(:theme1).id
      end

      assert_response :success, decoded_response['error']

      updated_theme.reload
      assert_equal RESET_THEME_DATA, updated_theme.data
    end

    test 'reset theme as group designer' do
      accept_json!
      valid_auth_header! :group1_designer

      data = {'test' => 'value'}

      put(:update,
          :id => autotune_themes(:theme1).id,
          :data => data)

      assert_response :success, decoded_response['error']

      updated_theme = Theme.find decoded_response['id']
      assert_equal data, updated_theme.data

      assert_performed_jobs 1 do
        put :reset, :id => autotune_themes(:theme1).id
      end

      assert_response :success, decoded_response['error']

      updated_theme.reload
      assert_equal RESET_THEME_DATA, updated_theme.data
    end

    test 'reset theme as author not allowed' do
      accept_json!
      valid_auth_header! :author

      put :reset, :id => autotune_themes(:theme1).id

      assert_response :forbidden, decoded_response['error']
    end

    test 'reset theme as editor not allowed' do
      accept_json!
      valid_auth_header! :editor

      put :reset, :id => autotune_themes(:theme1).id

      assert_response :forbidden, decoded_response['error']
    end

    test 'reset theme as group designer not allowed' do
      accept_json!
      valid_auth_header! :group1_designer

      put :reset, :id => autotune_themes(:theme2).id

      assert_response :forbidden, decoded_response['error']
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
