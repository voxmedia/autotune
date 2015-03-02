require 'test_helper'

# test the job for updating projects
class SyncProjectJobTest < ActiveJob::TestCase
  fixtures :blueprints, :projects

  test 'update snapshot' do
    b = projects(:example_one)

    # why must i do this?
    b.blueprint = blueprints(:example)
    b.save! && b.reload

    assert_equal blueprints(:example), b.blueprint

    assert_performed_jobs 0

    perform_enqueued_jobs do
      SyncBlueprintJob.perform_later b.blueprint
      SyncProjectJob.perform_later b
    end

    assert_performed_jobs 2

    assert_equal 'updated', b.status
  end
end
