require 'test_helper'

# Test build api
class BuildsControllerTest < ActionController::TestCase
  fixtures :blueprints, :builds, :users

  test 'that listing builds requires authentication' do
    accept_json!

    get :index
    assert_response :unauthorized
    assert_equal({ 'error' => 'Unauthorized' }, decoded_response)
  end

  test 'listing builds' do
    accept_json!
    valid_auth_header!

    get :index
    assert_response :success
    assert_instance_of Array, decoded_response
  end

  test 'show build' do
    accept_json!
    valid_auth_header!

    get :show, :id => builds(:example_one).id
    assert_response :success
    assert_build_data!
    assert_equal builds(:example_one).id, decoded_response['id']
  end

  test 'create build' do
    accept_json!
    valid_auth_header!

    title = 'New build'

    post :create, :title => title, :blueprint_id => blueprints(:example).id
    assert_response :created, decoded_response['error']
    assert_build_data!

    new_bp = Build.find decoded_response['id']
    assert_equal title, new_bp.title
  end

  test 'update build' do
    accept_json!
    valid_auth_header!

    title = 'Updated build'

    put(:update,
        :id => builds(:example_one).id,
        :title => title)
    assert_response :success, decoded_response['error']
    assert_build_data!

    new_bp = Build.find decoded_response['id']
    assert_equal title, new_bp.title
  end

  test 'delete build' do
    accept_json!
    valid_auth_header!

    delete :destroy, :id => builds(:example_one).id
    assert_response :no_content
  end

  test 'filter builds' do
    accept_json!
    valid_auth_header!

    get :index, :status => 'ready'
    assert_response :success
    assert_instance_of Array, decoded_response
    assert_equal 0, decoded_response.length
  end

  private

  def assert_build_data!
    assert_data %w(title slug id created_at updated_at)
  end
end
