class ChainJob < ActiveJob::Base
  queue_as :default

  def perform(val)
    if Rails.cache.exist? 'chainjob'
      v = Rails.cache.read('chainjob')
    else
      v = ''
    end

    Rails.cache.write('chainjob', v + val)
  end
end
