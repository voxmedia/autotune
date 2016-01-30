require 'test_helper'

# Test the install blueprint job
class Autotune::SyncBlueprintJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes'
  test 'install blueprint' do
    bp = autotune_blueprints(:example)

    assert_performed_jobs 0

    perform_enqueued_jobs do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    assert_performed_jobs 1

    bp.reload

    assert bp.installed?, 'Blueprint should be installed'
    assert_equal 'testing', bp.status    

    assert_equal '/media/example-blueprint/thumbnail.jpg', bp.thumb_url
  end
end
