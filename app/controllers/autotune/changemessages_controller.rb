require_dependency 'autotune/application_controller'
#require 'redis'

module Autotune
  # Send events to the clients
  class ChangemessagesController < ApplicationController
    include ActionController::Live

    KEEPALIVE_SEC = 60 # Make sure that this is lower than the server's timeout

    def index
      response.headers['Content-Type'] = 'text/event-stream'
      sse = SSE.new(response.stream, retry: 300, event: 'connectionopen')
      sse.write(msg: 'Channel init')
      stream_events(sse)
    ensure
      sse.close
    end

    private

    def stream_events(sse)
      counter = 0
      $redis.subscribe('blueprints', 'projects', 'heartbeat') do |on|
        on.message do |channel, msg|
          if (channel == 'heartbeat')
            counter += 1
            sse.write({ seconds: counter }, retry: 3000, event: 'heartbeat')
          else
            sse.write({ msg: msg }, event: 'change')
          end

          # Close connection before server can kill the thread
          if (counter == KEEPALIVE_SEC)
            sse.write(msg: 'Channel close')
            sse.close
          end
        end
      end
    end
  end
end
