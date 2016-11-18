require 'test_helper'

module Autotune
  # Test the projects
  class ProjectTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints', 'autotune/users', 'autotune/projects', 'autotune/themes', 'autotune/groups'

    test 'creating a project' do
      assert_raises ActiveRecord::RecordInvalid do
        Project.create!(:title => 'new project')
      end

      bp = autotune_blueprints(:example)

      assert_raises ActiveRecord::RecordInvalid do
        Project.create!(:title => 'new project', :blueprint => bp)
      end

      user = autotune_users(:developer)

      assert_raises ActiveRecord::RecordInvalid do
        Project.create!(:title => 'new project', :blueprint => bp, :user => user)
      end

      group = autotune_groups(:group1)

      theme = autotune_themes(:theme1)

      b = Project.create!(
        :title => 'new project', :blueprint => bp, :user => user, :theme => theme, :group => group)
      assert_equal b.blueprint, bp
      assert_equal b.user, user
      assert_equal 'new', b.status
    end

    test 'project meta' do
      project = Project.new
      assert_equal({}, project.meta)

      project = autotune_projects(:example_one)
      project.meta['thinga'] = 'foo'
      assert project.save
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
      assert_equal 4, Project.search('Example').count
      assert_equal 0, Project.search('foo').count
    end

    test 'slug automatic incrementing' do
      skip
      b = autotune_blueprints(:example)
      b.slug = 'new-blueprint'
      b.save!
      b.reload
      assert_equal 'new-blueprint', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint',
        :repo_url => repo_url + '#1')
      assert_equal 'new-blueprint-1', b.slug
      b.slug = 'new-blueprint'
      b.save!
      b.reload
      assert_equal 'new-blueprint-1', b.slug
      b.slug = 'new-blueprint-1'
      b.save!
      b.reload
      assert_equal 'new-blueprint-1', b.slug

      b = Blueprint.create!(
        :title => 'foo bar',
        :slug => 'foo-bar-50',
        :repo_url => repo_url + '#2')
      assert_equal 'foo-bar-50', b.slug

      b = Blueprint.create!(
        :title => 'foo bar',
        :slug => 'foo-bar-50',
        :repo_url => repo_url + '#3')
      assert_equal 'foo-bar-50-1', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint',
        :repo_url => repo_url + '#4')
      assert_equal 'new-blueprint-2', b.slug
      b.slug = 'new-blueprint'
      b.save!
      b.reload
      assert_equal 'new-blueprint-2', b.slug
      b.slug = 'new-blueprint-1'
      b.save!
      b.reload
      assert_equal 'new-blueprint-2', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint-1',
        :repo_url => repo_url + '#5')
      assert_equal 'new-blueprint-3', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint-5',
        :repo_url => repo_url + '#6')
      assert_equal 'new-blueprint-5', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint-5',
        :repo_url => repo_url + '#7')
      assert_equal 'new-blueprint-6', b.slug
    end

    test 'too much output' do
      output_limit = Autotune::Project.columns_hash['output'].limit || 64.kilobytes - 1

      project = autotune_projects(:example_one)

      # generate >64K of output
      options = ('a'..'z').to_a + (1..12).to_a
      options += %w(<b> </b> <div> </div> & < > <br> \n \" " \' \\\\\\' ` &amp; &lt; &gt;) + ["\n", ' '] + ["'"] * 10
      output = 65.kilobytes.times.map { options[rand(options.length)] }.join

      project.status = 'broken'
      project.output = output[0, 200]
      assert project.valid?
      assert project.save

      project.output = output

      assert_equal project.output, output

      begin
        project.save!
      rescue ActiveRecord::StatementInvalid
        flunk 'Failed to save project (sparing you a huge screen of junk)'
      end

      assert_operator project.output.length, :<=, output_limit
      assert_operator project.output.length, :<, output.length

      # check for a message at the end of the truncated output
      msg = '(truncated)'

      assert_operator project.output, :end_with?, msg,
                      'missing truncate message'
    end

    test 'build and publish' do
      project = autotune_projects(:example_one)

      assert_performed_jobs 3 do
        project.build_and_publish
      end
    end

    test 'build' do
      project = autotune_projects(:example_one)

      assert_performed_jobs 3 do
        project.build
      end
    end

    test 'upgrayyyyyde' do
      project = autotune_projects(:example_one)

      assert_performed_jobs 3 do
        project.update_snapshot
      end
    end

    test 'live' do
      project = autotune_projects(:example_one)

      refute project.live?
    end
  end
end
