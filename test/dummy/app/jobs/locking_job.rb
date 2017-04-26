class LockingJob < ActiveJob::Base
  queue_as :default

  lock_job :retry => 20.seconds

  def perform
    puts 'locking job'
  end
end
