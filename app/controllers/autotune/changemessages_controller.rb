require_dependency 'autotune/application_controller'

module Autotune
  # Send events to the clients
  class ChangemessagesController < ApplicationController
    include ActionController::Live

    KEEPALIVE_SEC = 60 # Make sure that this is lower than the server's timeout

    def index
      response.headers['Content-Type'] = 'text/event-stream'
      sse = SSE.new(response.stream, retry: 300, event: 'connectionopen')
      sse.write(msg: 'Channel init')
      # heartbeat(sse)
      stream_events(sse)
    ensure
      sse.close
    end

    private

    def stream_events(sse)
      Autotune.redis.subscribe('blueprints', 'projects') do |on|
        on.message do |_channel, msg|
          sse.write({ msg: msg }, event: 'change')
        end
      end
    end

    def heartbeat(sse)
      Thread.new do
        counter = 1
        while counter <= KEEPALIVE_SEC
          begin
            sse.write({ msg: counter }, retry: 3000, event: 'heartbeats')
            counter += 1
            sleep 1
          rescue IOError
            sse.close
            Thread.exit
          end
        end
        sse.write({ msg: 'Channel close' }, event: 'connectionclose')
        sse.close
        Thread.exit
      end
    end
  end
end
