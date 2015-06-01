require 'test_helper'

module Autotune
  # Test project api
  class ProjectsControllerTest < ActionController::TestCase
    fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes'
    test 'that listing projects requires authentication' do
      accept_json!

      get :index
      assert_response :unauthorized
      assert_equal({ 'error' => 'Unauthorized' }, decoded_response)
    end

    test 'listing projects' do
      accept_json!
      valid_auth_header!

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal decoded_response.length, 3
    end

    test 'listing projects as author' do
      accept_json!
      valid_auth_header! :author

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal decoded_response.length, 1
    end

    test 'show project' do
      accept_json!
      valid_auth_header!

      get :show, :id => autotune_projects(:example_one).id
      assert_response :success
      assert_project_data!
      assert_equal autotune_projects(:example_one).id, decoded_response['id']
    end

    test 'show project not allowed' do
      accept_json!
      valid_auth_header! :author

      get :show, :id => autotune_projects(:example_one).id
      assert_response :forbidden
    end

    test 'show non-existant project' do
      accept_json!
      valid_auth_header!

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, :id => 'foobar'
      end
    end

    test 'create project' do
      accept_json!
      valid_auth_header!

      post :create, project_data

      assert_response :created, decoded_response['error']
      assert_project_data!

      new_p = Project.find decoded_response['id']
      assert_equal project_data[:title], new_p.title
    end

    test 'update project' do
      accept_json!
      valid_auth_header!

      title = 'Updated project'

      put(:update,
          :id => autotune_projects(:example_one).id,
          :title => title)
      assert_response :success, decoded_response['error']
      assert_project_data!

      new_p = Project.find decoded_response['id']
      assert_equal title, new_p.title
    end

    test 'delete project' do
      accept_json!
      valid_auth_header!

      delete :destroy, :id => autotune_projects(:example_one).id
      assert_response :no_content
    end

    test 'filter projects' do
      accept_json!
      valid_auth_header!

      get :index, :status => 'ready'
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal 0, decoded_response.length
    end

    private

    def assert_project_data!
      assert_data project_data.keys
    end

    def project_data
      @project_data ||= {
        :title => 'New project',
        :slug => 'New project'.parameterize,
        :blueprint_id => autotune_blueprints(:example).id,
        :user_id => autotune_users(:developer).id,
        :theme => autotune_themes(:generic).value,
        :preview_url => '',
        :data => {
          :title => 'New project',
          :slug => 'New project'.parameterize,
          :theme => 'default',
          :google_doc_id => '1234'
        }
      }
    end
  end
end
