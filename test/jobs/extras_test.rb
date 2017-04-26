require 'test_helper'

# test the project job
class ActiveJobExtrasTest < ActiveJob::TestCase

  test 'chaining' do
    assert_performed_jobs 0

    perform_enqueued_jobs do
      ActiveJob::Chain.new(
        ChainJob.new,
        ChainJob.new,
        ChainJob.new
      ).enqueue
    end

    assert_performed_jobs 3

    perform_enqueued_jobs do
      ChainJob.new
        .then(ChainJob.new)
        .then(ChainJob.new)
        .enqueue
    end

    assert_performed_jobs 6
  end

  test 'unique job' do

  end

  test 'locking' do

  end

  test 'chained uniques' do

  end

  test 'chained locked' do

  end

  test 'locked unique' do

  end

  test 'chained locked unique' do

  end
end
