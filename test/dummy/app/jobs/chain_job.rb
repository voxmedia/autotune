class ChainJob < ActiveJob::Base
  queue_as :default

  def perform
    puts 'chain job'
  end
end
