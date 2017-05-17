require 'test_helper'

# test the project job
class ActiveJobExtrasTest < ActiveJob::TestCase

  test 'chaining' do
    assert_performed_jobs 0

    perform_enqueued_jobs do
      ActiveJob::Chain.new(
        ChainJob.new('one'),
        ChainJob.new('two'),
        ChainJob.new('three')
      ).enqueue
    end

    assert_performed_jobs 3
    assert_equal 'onetwothree',
                 Rails.cache.read('chainjob')
    Rails.cache.delete('chainjob')

    perform_enqueued_jobs do
      job = ChainJob.new('four')
      job
        .then(ChainJob.new('five'))
        .then(ChainJob.new('six'))
      job.enqueue
    end

    assert_performed_jobs 6
    assert_equal 'fourfivesix',
                 Rails.cache.read('chainjob')
    Rails.cache.delete('chainjob')
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
