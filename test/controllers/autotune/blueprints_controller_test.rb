require 'test_helper'

# All the tests involving a repo use a git repo in the test/repos directory. If
# you need to make adjustments to this repo, clone it locally by doing
# something like:
#   git clone ../autotune/test/repos/autotune-example-blueprint.git

module Autotune
  # Test blueprint api
  class BlueprintsControllerTest < ActionController::TestCase
    fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/users', 'autotune/groups', 'autotune/group_memberships'
    test 'that listing blueprints requires authentication' do
      accept_json!

      get :index
      assert_response :unauthorized
      assert_equal({ 'error' => 'Unauthorized' }, decoded_response)
    end

    test 'listing blueprints' do
      accept_json!
      valid_auth_header!

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal autotune_blueprints(:example).id, decoded_response.first['id']
    end

    test 'listing blueprints as author' do
      accept_json!
      valid_auth_header! :author

      get :index
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal autotune_blueprints(:example).id, decoded_response.first['id']
    end

    test 'show blueprint' do
      accept_json!
      valid_auth_header!

      get :show, :id => autotune_blueprints(:example).id
      assert_response :success
      assert_blueprint_data!
      assert_equal autotune_blueprints(:example).id, decoded_response['id']
    end

    test 'show non-existant blueprint' do
      accept_json!
      valid_auth_header!

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, :id => 'foobar'
      end
    end

    test 'create blueprint' do
      # make sure we remove the example blueprint
      repo_url = autotune_blueprints(:example).repo_url
      autotune_blueprints(:example).projects.destroy_all
      autotune_blueprints(:example).destroy

      accept_json!
      valid_auth_header!

      title = 'New blueprint'

      assert_performed_jobs 1 do
        post :create, :title => title, :repo_url => repo_url
      end

      assert_response :created
      assert_blueprint_data!

      new_bp = Blueprint.find decoded_response['id']
      assert_equal title, new_bp.title
    end

    test 'update blueprint' do
      accept_json!
      valid_auth_header!

      title = 'Updated blueprint'

      assert_no_performed_jobs do
        put(:update,
            :id => autotune_blueprints(:example).id,
            :title => title)
      end
      assert_response :success
      assert_blueprint_data!

      new_bp = Blueprint.find decoded_response['id']
      assert_equal title, new_bp.title
    end

    test 'delete blueprint' do
      # make sure we remove the example blueprint
      repo_url = autotune_blueprints(:example).repo_url
      autotune_blueprints(:example).projects.destroy_all
      autotune_blueprints(:example).destroy

      accept_json!
      valid_auth_header!

      title = 'New blueprint'

      assert_performed_jobs 1 do
        post :create, :title => title, :repo_url => repo_url
      end

      assert_response :created
      assert_blueprint_data!

      assert_performed_jobs 2 do
        delete :destroy, :id => decoded_response['id']
      end

      assert_response :no_content
    end

    test 'delete blueprint with projects' do
      # make sure we remove the example blueprint
      bp = autotune_blueprints(:example)
      assert bp.projects.count > 0

      accept_json!
      valid_auth_header!

      delete :destroy, :id => bp.id
      assert_response :bad_request
    end

    test 'filter blueprints' do
      accept_json!
      valid_auth_header!

      get :index, :status => 'ready'
      assert_response :success
      assert_instance_of Array, decoded_response
      assert_equal 0, decoded_response.length
    end

    test 'update blueprint repo url' do
      accept_json!
      valid_auth_header!

      bp = autotune_blueprints(:example)

      assert bp.present?, 'Example blueprint fixture should exist'

      title = 'Updated blueprint'

      assert_performed_jobs 1 do
        put(:update,
            :id => bp.id,
            :title => title,
            :repo_url => "#{bp.repo_url}#live")
      end
      assert_response :success
      assert_blueprint_data!

      new_bp = Blueprint.find decoded_response['id']
      assert_equal title, new_bp.title
    end

    private

    def assert_blueprint_data!
      assert_data %w(title slug id repo_url config created_at updated_at)
    end
  end
end
