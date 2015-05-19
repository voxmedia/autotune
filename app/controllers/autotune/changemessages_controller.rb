require_dependency 'autotune/application_controller'

module Autotune
  # Send events to the clients
  class ChangemessagesController < ApplicationController
    include ActionController::Live

    before_action :close_db_connection

    TIMEOUT = 60

    def index
      t1 = Time.now.to_f
      logger.info 'Client stream connected'
      response.headers['Content-Type'] = 'text/event-stream'
      sse = SSE.new(response.stream, retry: 300, event: 'connectionopen')
      sse.write(msg: 'Channel init')

      redis_thread = Thread.new do
        Thread.current.abort_on_exception = true
        Autotune.redis.subscribe('blueprints', 'projects') do |on|
          on.message do |_channel, msg|
            sse.write({ msg: msg }, event: 'change')
          end
        end
      end

      loop do
        if Time.now.to_f - t1 > TIMEOUT
          logger.info 'Preemptive stream timeout'
          sse.write(msg: 'Channel close', event: 'connectionclose')
          break
        end
        sse.write(msg: 'pong', event: 'ping')
        sleep 2
      end
    rescue ClientDisconnected
      logger.info 'Client stream disconnected'
    ensure
      sse.close
      if redis_thread.alive?
        logger.info 'Teardown redis thread'
        redis_thread.exit
      end
      logger.info 'Cleaned up stream threads'
    end

    private

    def close_db_connection
      ActiveRecord::Base.connection_pool.release_connection
    end
  end
end
