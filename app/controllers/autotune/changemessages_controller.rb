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
      stream_events(sse, Time.zone.now)
    ensure
      sse.close
    end

    private

    def stream_events(sse, start_time)
      $redis.subscribe('blueprints', 'projects', 'heartbeat') do |on|
        on.message do |channel, msg|
          if (channel == 'heartbeat')
            sse.write({ msg: msg }, retry: 3000, event: 'heartbeat')
          else
            sse.write({ msg: msg }, event: 'change')
          end

          # Close connection before server can kill the thread
          time_alive = Time.zone.now - start_time
          if (time_alive >= KEEPALIVE_SEC)
            sse.write({ msg: 'Channel close', timeAlive: time_alive }, event: 'connectionclose')
            sse.close
          end
        end
      end
    end
  end
end
