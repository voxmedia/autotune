require 'test_helper'

module Autotune
  # Test the projects
  class ProjectTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'
    fixtures 'autotune/users'
    test 'creating a project' do
      assert_raises ActiveRecord::RecordInvalid do
        Project.create!(:title => 'new project')
      end

      bp = autotune_blueprints(:example)

      assert_raises ActiveRecord::RecordInvalid do
        Project.create!(:title => 'new project', :blueprint => bp)
      end

      user = autotune_users(:developer)

      b = Project.create!(
        :title => 'new project', :blueprint => bp, :user => user)
      assert_equal b.blueprint, bp
      assert_equal b.user, user
      assert_equal 'new', b.status
    end

    test 'search projects' do
      assert_equal 3, Project.search('Example').count
      assert_equal 0, Project.search('foo').count
    end
  end
end
