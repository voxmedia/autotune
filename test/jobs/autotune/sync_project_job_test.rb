require 'test_helper'

# test the job for updating projects
class Autotune::SyncProjectJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/users'
  test 'update snapshot' do
    b = autotune_projects(:example_one)

    assert_equal autotune_blueprints(:example), b.blueprint

    assert_performed_jobs 0

    #perform_enqueued_jobs do
      #Autotune::SyncProjectJob.perform_later b
    #end

    #assert_performed_jobs 1

    #b.reload

    #assert_equal 'updated', b.status
  end
end
