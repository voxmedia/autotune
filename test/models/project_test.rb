require 'test_helper'

# Test the projects
class ProjectTest < ActiveSupport::TestCase
  test 'creating a project' do
    assert_raises ActiveRecord::RecordInvalid do
      Project.create!(:title => 'new project')
    end

    bp = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => repo_url)

    b = Project.create!(:title => 'new project', :blueprint => bp)
    assert_equal b.blueprint, bp
    assert_equal 'new', b.status
  end
end
