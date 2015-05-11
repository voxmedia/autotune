require_dependency 'autotune/application_controller'
require 'redis'

module Autotune
  # Send events to the clients
  class ChangemessagesController < ApplicationController
    include ActionController::Live

    def index
      response.headers['Content-Type'] = 'text/event-stream'
      sse = SSE.new(response.stream, retry: 300, event: 'change')
      sse.write(msg: 'Channel init')

      $redis.subscribe('blueprints', 'projects') do |on|
        on.message do |_channel, msg|
          sse.write(msg: msg)
        end
      end
    ensure
      sse.close
    end
  end
end
