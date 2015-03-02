require 'test_helper'

# Test project api
class ProjectsControllerTest < ActionController::TestCase
  fixtures :blueprints, :projects, :users

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
  end

  test 'show project' do
    accept_json!
    valid_auth_header!

    get :show, :id => projects(:example_one).id
    assert_response :success
    assert_project_data!
    assert_equal projects(:example_one).id, decoded_response['id']
  end

  test 'create project' do
    accept_json!
    valid_auth_header!

    title = 'New project'

    post :create, :title => title, :blueprint_id => blueprints(:example).id
    assert_response :created, decoded_response['error']
    assert_project_data!

    new_bp = Project.find decoded_response['id']
    assert_equal title, new_bp.title
  end

  test 'update project' do
    accept_json!
    valid_auth_header!

    title = 'Updated project'

    put(:update,
        :id => projects(:example_one).id,
        :title => title)
    assert_response :success, decoded_response['error']
    assert_project_data!

    new_bp = Project.find decoded_response['id']
    assert_equal title, new_bp.title
  end

  test 'delete project' do
    accept_json!
    valid_auth_header!

    delete :destroy, :id => projects(:example_one).id
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
    assert_data %w(title slug id created_at updated_at)
  end
end
