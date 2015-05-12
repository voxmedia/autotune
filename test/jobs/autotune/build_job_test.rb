require 'test_helper'

# test the project job
class Autotune::BuildJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects'
  test 'building' do
    b = autotune_projects(:example_one)

    assert_equal autotune_blueprints(:example), b.blueprint

    assert_not_nil Rails.configuration.autotune.preview

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

    snapshot = WorkDir.snapshot(b.working_dir)

    assert snapshot.exist?, 'Snapshot should exist'
    assert !snapshot.git?, 'Snapshot should not be a git repo'
  end
end
