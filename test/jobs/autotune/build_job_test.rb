require 'test_helper'

# test the project job
class Autotune::BuildJobTest < ActiveJob::TestCase
  fixtures 'autotune/users', 'autotune/blueprints', 'autotune/projects', 'autotune/themes'
  test 'building' do
    b = autotune_projects(:example_one)

    assert_equal autotune_blueprints(:example), b.blueprint
    assert_equal autotune_users(:developer), b.user

    assert_performed_jobs 0

    perform_enqueued_jobs do
      Autotune::BuildJob.perform_later b
    end

    assert_performed_jobs 1

    b.reload

    assert_equal 'built', b.status
    assert_match(/Build data:/, b.output)

    assert File.exist?(Rails.root.join('public', 'preview', b.slug, 'index.html')),
           'Built file should be deployed to public/preview'

    snapshot = WorkDir.repo(b.working_dir)

    assert snapshot.exist?, 'Snapshot should exist'
    assert snapshot.git?, 'Snapshot should be a git repo'
    assert snapshot.exist?('build/screenshots/screenshot_l.png'), 'Snapshot should have screenies'
  end
end
