require 'test_helper'

# Test the install blueprint job
class Autotune::SyncBlueprintJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects'
  test 'install blueprint' do
    bp = autotune_blueprints(:example)
    bp.repo.rm if bp.installed?

    assert_performed_jobs 0

    perform_enqueued_jobs do
      Autotune::SyncBlueprintJob.perform_later bp
    end

    assert_performed_jobs 1

    bp.reload

    assert bp.installed?, 'Blueprint should be installed'
    assert_equal 'testing', bp.status
  end
end
