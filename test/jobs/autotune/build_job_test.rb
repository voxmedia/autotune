require 'test_helper'

# test the project job
class Autotune::BuildJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects'
  test 'building' do
    b = autotune_projects(:example_one)

    assert_equal autotune_blueprints(:example), b.blueprint

    assert_performed_jobs 0

    perform_enqueued_jobs do
      Autotune::SyncBlueprintJob.perform_later b.blueprint
      Autotune::BuildJob.perform_later b
    end

    assert_performed_jobs 2

    assert_equal 'built', b.status
    assert_match(/Build data:/, b.output)

    assert b.snapshot.exist?, 'Snapshot should exist'
    assert !b.snapshot.git?, 'Snapshot should not be a git repo'
  end
end
