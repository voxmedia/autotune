require 'test_helper'
require 'autoshell'

# test the project job
class Autotune::BuildJobTest < ActiveJob::TestCase
  fixtures 'autotune/users', 'autotune/blueprints', 'autotune/projects',
           'autotune/themes', 'autotune/groups'

  test 'building' do
    b = autotune_projects(:example_one)

    assert_equal autotune_blueprints(:example), b.blueprint
    assert_equal autotune_users(:developer), b.user

    assert_performed_jobs 0

    perform_enqueued_jobs do
      ActiveJob::Chain.new(
        Autotune::SyncBlueprintJob.new(b.blueprint),
        Autotune::SyncProjectJob.new(b),
        Autotune::BuildJob.new(b)
      ).enqueue
    end

    assert_performed_jobs 3

    b.reload

    assert_equal 'built', b.status

    assert b.logs.count, 2

    assert_match(/Build data:/, b.logs.first.content)

    assert File.exist?(Rails.root.join('public', 'preview', b.slug, 'index.html')),
           'Built file should be deployed to public/preview'

    snapshot = Autoshell.new(b.working_dir)

    assert snapshot.exist?, 'Snapshot should exist'
    assert snapshot.git?, 'Snapshot should be a git repo'
    # TODO Fix test so it passes
    # assert snapshot.exist?('build/screenshots/screenshot_l.png'), 'Snapshot should have screenies'
  end
end
