require 'test_helper'

module Autotune
  # Test project api
  class ProjectsControllerTest < ActionController::TestCase
    fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes', 'autotune/users'
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
      assert_equal Project.all.count, decoded_response.length
    end

    test 'listing projects as author' do
      accept_json!
      valid_auth_header! :author

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal autotune_users(:author).projects.count, decoded_response.length
    end

    test 'listing projects as editor' do
      accept_json!
      valid_auth_header! :editor

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Project.all.count, decoded_response.length
    end

    test 'listing projects as generic author' do
      accept_json!
      valid_auth_header! :generic_author

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal autotune_users(:generic_author).projects.count, decoded_response.length
    end

    test 'listing projects as generic editor' do
      accept_json!
      valid_auth_header! :generic_editor

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Project.where(:theme => autotune_themes(:generic)).count, decoded_response.length
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

    test 'show project as editor' do
      accept_json!
      valid_auth_header! :editor

      get :show, :id => autotune_projects(:example_one).id
      assert_response :success
    end

    test 'show project as theme editor' do
      accept_json!
      valid_auth_header! :generic_editor

      get :show, :id => autotune_projects(:example_one).id
      assert_response :success
    end

    test 'show project as theme editor not allowed' do
      accept_json!
      valid_auth_header! :generic_editor

      get :show, :id => autotune_projects(:example_four).id
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

      assert_performed_jobs 3 do
        post :create, project_data
      end

      assert_response :created, decoded_response['error']
      assert_project_data!

      new_p = Project.find decoded_response['id']
      assert_equal project_data[:title], new_p.title
    end

    test 'create project not allowed' do
      accept_json!
      valid_auth_header! :generic_author

      post :create, project_data.update(:theme => autotune_themes(:vox).value)
      assert_response :bad_request, decoded_response['error']
    end

    test 'update project' do
      accept_json!
      valid_auth_header!

      title = 'Updated project'

      assert_performed_jobs 3 do
        put(:update,
            :id => autotune_projects(:example_one).id,
            :title => title)
      end

      assert_response :success, decoded_response['error']
      assert_project_data!

      new_p = Project.find decoded_response['id']
      assert_equal title, new_p.title
    end

    test 'update project as author' do
      accept_json!
      valid_auth_header! :author

      title = 'Updated project'

      assert_performed_jobs 3 do
        put(:update,
            :id => autotune_projects(:example_six).id,
            :title => title)
      end
      assert_response :success, decoded_response['error']
      assert_project_data!

      new_p = Project.find decoded_response['id']
      assert_equal title, new_p.title
    end

    test 'update project as author not allowed' do
      accept_json!
      valid_auth_header! :author

      title = 'Updated project'

      put(:update,
          :id => autotune_projects(:example_one).id,
          :title => title)
      assert_response :forbidden, decoded_response['error']
    end

    test 'update project as editor' do
      accept_json!
      valid_auth_header! :editor

      title = 'Updated project'

      assert_performed_jobs 3 do
        put(:update,
            :id => autotune_projects(:example_one).id,
            :title => title)
      end
      assert_response :success, decoded_response['error']
      assert_project_data!

      new_p = Project.find decoded_response['id']
      assert_equal title, new_p.title
    end

    test 'update project as theme editor' do
      accept_json!
      valid_auth_header! :generic_editor

      title = 'Updated project'

      assert_performed_jobs 3 do
        put(:update,
            :id => autotune_projects(:example_one).id,
            :title => title)
      end
      assert_response :success, decoded_response['error']
      assert_project_data!

      new_p = Project.find decoded_response['id']
      assert_equal title, new_p.title
    end

    test 'update project as theme editor not allowed' do
      accept_json!
      valid_auth_header! :generic_editor

      title = 'Updated project'

      put(:update,
          :id => autotune_projects(:example_four).id,
          :title => title)
      assert_response :forbidden, decoded_response['error']
    end

    test 'delete project' do
      accept_json!
      valid_auth_header!

      delete :destroy, :id => autotune_projects(:example_one).id
      assert_response :no_content
    end

    test 'delete project as author not allowed' do
      accept_json!
      valid_auth_header! :author

      delete :destroy, :id => autotune_projects(:example_one).id
      assert_response :forbidden
    end

    test 'delete project as author' do
      accept_json!
      valid_auth_header! :author

      delete :destroy, :id => autotune_projects(:example_six).id
      assert_response :no_content
    end

    test 'delete project as editor' do
      accept_json!
      valid_auth_header! :editor

      delete :destroy, :id => autotune_projects(:example_six).id
      assert_response :no_content
    end

    test 'delete project as theme editor' do
      accept_json!
      valid_auth_header! :generic_editor

      delete :destroy, :id => autotune_projects(:example_one).id
      assert_response :no_content
    end

    test 'delete project as theme editor not allowed' do
      accept_json!
      valid_auth_header! :generic_editor

      delete :destroy, :id => autotune_projects(:example_four).id
      assert_response :forbidden
    end

    test 'filter projects' do
      accept_json!
      valid_auth_header!

      get :index, :status => 'ready'
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Project.where(:status => 'ready').count, decoded_response.length
    end

    test 'filter projects as editor' do
      accept_json!
      valid_auth_header!

      get :index, :status => 'new'
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Project.where(:status => 'new').count, decoded_response.length
    end

    test 'filter projects as theme editor' do
      accept_json!
      valid_auth_header! :generic_editor

      get :index, :status => 'new'
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Project.where(:theme => autotune_themes(:generic)).count,
                   decoded_response.length
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
