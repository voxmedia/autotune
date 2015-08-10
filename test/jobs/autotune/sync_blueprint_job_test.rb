require 'test_helper'

# Test the install blueprint job
class Autotune::SyncBlueprintJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes'
  test 'install blueprint' do
    bp = autotune_blueprints(:example)
    # the fixture has 5 themes
    assert_equal 5, bp.themes.count

    assert_performed_jobs 0

    perform_enqueued_jobs do
      Autotune::SyncBlueprintJob.perform_later bp
    end

    assert_performed_jobs 1

    bp.reload

    assert bp.installed?, 'Blueprint should be installed'
    assert_equal 'testing', bp.status
    # only `generic` and `vox` themes are enabled for the test suite
    # the sync should have reset all the themes to just the one available
    assert_equal 2, bp.themes.count

    assert_equal '/media/example-blueprint/thumbnail.jpg', bp.thumb_url
  end
end
