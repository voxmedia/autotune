class LockingJob < ActiveJob::Base
  queue_as :default

  unique_job :with => :payload

  def perform
    puts 'locking job'
  end
end
