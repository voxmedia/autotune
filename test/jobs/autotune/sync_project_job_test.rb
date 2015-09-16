require 'test_helper'

# test the job for updating projects
class Autotune::SyncProjectJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/users'
  test 'update snapshot' do
    b = autotune_projects(:example_one)

    assert_equal autotune_blueprints(:example), b.blueprint

    assert_performed_jobs 0

    perform_enqueued_jobs do
      ActiveJob::Chain.new(
        Autotune::SyncBlueprintJob.new(b.blueprint),
        Autotune::SyncProjectJob.new(b)
      ).enqueue
    end

    assert_performed_jobs 2

    b.reload

    assert_equal 'updated', b.status
  end
end
