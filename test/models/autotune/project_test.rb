require 'test_helper'

# Test the projects
class Autotune::ProjectTest < ActiveSupport::TestCase
  fixtures 'autotune/blueprints'
  test 'creating a project' do
    assert_raises ActiveRecord::RecordInvalid do
      Autotune::Project.create!(:title => 'new project')
    end

    bp = autotune_blueprints(:example)

    b = Autotune::Project.create!(:title => 'new project', :blueprint => bp)
    assert_equal b.blueprint, bp
    assert_equal 'new', b.status
  end
end
