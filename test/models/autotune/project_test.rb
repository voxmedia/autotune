require 'test_helper'

module Autotune
  # Test the projects
  class ProjectTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'
    test 'creating a project' do
      assert_raises ActiveRecord::RecordInvalid do
        Project.create!(:title => 'new project')
      end

      bp = autotune_blueprints(:example)

      b = Project.create!(:title => 'new project', :blueprint => bp)
      assert_equal b.blueprint, bp
      assert_equal 'new', b.status
    end

    test 'search projects' do
      assert_equal 2, Project.search('Example').count
      assert_equal 0, Project.search('foo').count
    end
  end
end
