require 'test_helper'

# test the build job
class BuildJobTest < ActiveJob::TestCase
  fixtures :blueprints, :builds

  test 'building' do
    b = builds(:example_one)

    # why must i do this?
    b.blueprint = blueprints(:example)
    b.save! && b.reload

    assert_equal blueprints(:example), b.blueprint

    assert_performed_jobs 0

    perform_enqueued_jobs do
      BuildJob.perform_later b
    end

    assert_performed_jobs 1

    assert_equal 'built', b.status
    assert_match(/Build data:/, b.output)
  end
end
