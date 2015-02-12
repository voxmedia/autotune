require 'test_helper'

# Test the install blueprint job
class InstallBlueprintJobTest < ActiveJob::TestCase
  fixtures :blueprints

  test 'install blueprint' do
    bp = blueprints(:example)
    bp.uninstall! if bp.installed?

    assert_performed_jobs 0

    perform_enqueued_jobs do
      InstallBlueprintJob.perform_later bp
    end

    assert_performed_jobs 1

    assert bp.installed?
    assert_equal 'testing', bp.status
  end
end
