require 'test_helper'

module Autotune
  # Test the projects
  class ProjectTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'
    fixtures 'autotune/users'
    fixtures 'autotune/projects'

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

    test 'updating a project' do
      project = autotune_projects(:example_one)
      project.update!(:title => 'new project')
      assert_equal project.title, 'new project'
      assert_nil project.data_updated_at

      bp = autotune_blueprints(:example_two)
      project.update!(:blueprint => bp)
      assert_equal project.blueprint, bp
      assert_nil project.data_updated_at

      user = autotune_users(:author)
      project.update!(:user => user)
      assert_equal project.blueprint, bp
      assert_equal project.user, user
      assert_nil project.data_updated_at
    end

    test 'data updated timestamp' do
      project = autotune_projects(:example_one)

      assert_nil project.data_updated_at
      project.data['foo'] = 'bar'
      project.save!
      assert_not_nil project.data_updated_at
    end

    test 'updated since publish' do
      project = autotune_projects(:example_one)

      assert project.draft?
      assert !project.published?
      assert !project.unpublished_updates?

      assert_nil project.published_at
      assert_nil project.data_updated_at

      project.data['foo'] = 'bar'
      project.save!

      assert project.draft?
      assert !project.published?
      assert !project.unpublished_updates?

      assert_not_nil project.data_updated_at
      assert_nil project.published_at

      dt = DateTime.current
      project.update!(:published_at => dt)

      assert_equal project.published_at, dt

      assert !project.draft?
      assert project.published?
      assert !project.unpublished_updates?

      assert_not_nil project.data_updated_at
      assert_not_nil project.published_at

      project.data['foo'] = 'baz'
      project.save!

      assert !project.draft?
      assert project.published?
      assert project.unpublished_updates?
    end

    test 'search projects' do
      assert_equal 3, Project.search('Example').count
      assert_equal 0, Project.search('foo').count
    end
  end
end
