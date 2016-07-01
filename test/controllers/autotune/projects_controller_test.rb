require 'test_helper'

module Autotune
  # Test project api
  class ProjectsControllerTest < ActionController::TestCase
    fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes',
             'autotune/users', 'autotune/groups', 'autotune/group_memberships'
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

    test 'listing projects as group author' do
      accept_json!
      valid_auth_header! :group2_author

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal autotune_users(:group2_author).projects.count, decoded_response.length
    end

    test 'listing projects as group editor' do
      accept_json!
      valid_auth_header! :group1_editor

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Project.where(:group => autotune_groups(:group1)).count, decoded_response.length
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

    test 'show project as group editor' do
      accept_json!
      valid_auth_header! :group1_editor

      get :show, :id => autotune_projects(:example_one).id
      assert_response :success
    end

    test 'show project as group editor not allowed' do
      accept_json!
      valid_auth_header! :group1_editor

      get :show, :id => autotune_projects(:example_three).id
      assert_response :forbidden
    end

    test 'show non-existent project' do
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
      project_data.keys.each do |k|
        if k == :theme
          assert_equal Autotune::Theme.find_by_slug(project_data[k]), new_p.send(k)
        elsif k == :preview_url
          assert_equal '/preview/theme1-new-project', new_p.send(k)
        elsif k == :data
          assert_equal({ 'google_doc_id' => '1234' }, new_p.send(k))
        else
          assert_equal project_data[k], new_p.send(k)
        end
      end
    end

    test 'create project not allowed' do
      accept_json!
      valid_auth_header! :group2_author

      post :create, project_data.update(:theme => autotune_themes(:theme1).slug)
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

      title = 'Updated project as author'

      assert_performed_jobs 3 do
        put(:update,
            :id => autotune_projects(:example_four).id,
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

    test 'update project as group editor' do
      accept_json!
      valid_auth_header! :group1_editor

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

    test 'update project as group editor not allowed' do
      accept_json!
      valid_auth_header! :group1_editor

      title = 'Updated project'

      put(:update,
          :id => autotune_projects(:example_three).id,
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

      delete :destroy, :id => autotune_projects(:example_four).id
      assert_response :no_content
    end

    test 'delete project as editor' do
      accept_json!
      valid_auth_header! :editor

      delete :destroy, :id => autotune_projects(:example_four).id
      assert_response :no_content
    end

    test 'delete project as group editor' do
      accept_json!
      valid_auth_header! :group1_editor

      delete :destroy, :id => autotune_projects(:example_one).id
      assert_response :no_content
    end

    test 'delete project as group editor not allowed' do
      accept_json!
      valid_auth_header! :group1_editor

      delete :destroy, :id => autotune_projects(:example_two).id
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

    test 'filter projects as group editor' do
      accept_json!
      valid_auth_header! :group1_editor

      get :index, :status => 'new'
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal Project.where(:theme => autotune_themes(:theme1)).count,
                   decoded_response.length
    end

    test 'project versioning' do
      accept_json!
      valid_auth_header!

      bp = autotune_blueprints(:example)
      bp.update :version => MASTER_HEAD2

      assert_performed_jobs 3 do
        post :create, project_data
      end

      assert_response :created, decoded_response['error']
      assert_project_data!

      bp.reload
      assert_equal MASTER_HEAD2, bp.version,
                   'Repo should be checked out to the correct version'
      assert_equal MASTER_HEAD2, decoded_response['blueprint_version']

      new_p = Project.find decoded_response['id']
      assert_equal MASTER_HEAD2, new_p.blueprint_version
    end

    test 'project versioning with live preview' do
      accept_json!
      valid_auth_header!

      bp = autotune_blueprints(:example)
      bp.update(:repo_url => "#{bp.repo_url}#live", :version => LIVE_HEAD1)

      assert_performed_jobs 3 do
        post :create, project_data
      end

      assert_response :created, decoded_response['error']
      assert_project_data!

      bp.reload
      assert_equal LIVE_HEAD1, bp.version,
                   'Repo should be checked out to the correct version'
      assert_equal LIVE_HEAD1, decoded_response['blueprint_version']

      new_p = Project.find decoded_response['id']
      assert_equal LIVE_HEAD1, new_p.blueprint_version
    end

    test 'json request not blocked by google auth requirement' do
      Autotune.config.google_auth_enabled = true
      valid_auth_header!

      get :index
      assert_response :ok
      assert_match 'Please authenticate with Google', response.body,
                   'Should display message about logging in with Google'

      accept_json!

      get :index
      assert_response :ok
      assert_instance_of Array, decoded_response
      assert_equal Project.all.count, decoded_response.length
    end

    private

    def assert_project_data!
      assert_data project_data.keys
    end

    def project_data
      @project_data ||= {
        :title => 'New project',
        :slug => "#{autotune_themes(:theme1).slug} New project".parameterize,
        :blueprint_id => autotune_blueprints(:example).id,
        :user_id => autotune_users(:developer).id,
        :theme => autotune_themes(:theme1).slug,
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
