require 'test_helper'

# test the job for updating builds
class SyncBuildJobTest < ActiveJob::TestCase
  fixtures :blueprints, :builds

  test 'update snapshot' do
    b = builds(:example_one)

    # why must i do this?
    b.blueprint = blueprints(:example)
    b.save! && b.reload

    assert_equal blueprints(:example), b.blueprint

    assert_performed_jobs 0

    perform_enqueued_jobs do
      SyncBlueprintJob.perform_later b.blueprint
      SyncBuildJob.perform_later b
    end

    assert_performed_jobs 2

    assert_equal 'updated', b.status
  end
end
