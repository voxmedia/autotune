require 'test_helper'

# Test the install blueprint job
class SyncBlueprintJobTest < ActiveJob::TestCase
  fixtures :blueprints

  test 'install blueprint' do
    bp = blueprints(:example)
    bp.repo.rm if bp.installed?

    assert_performed_jobs 0

    perform_enqueued_jobs do
      SyncBlueprintJob.perform_later bp
    end

    assert_performed_jobs 1

    assert bp.installed?, 'Blueprint should be installed'
    assert_equal 'testing', bp.status
  end
end
