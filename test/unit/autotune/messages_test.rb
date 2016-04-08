require 'test_helper'

# Test the message bus
class Autotune::MessagesTest < ActiveSupport::TestCase
  setup do
    skip 'Cannot run tests without Redis' if Autotune.redis.nil?
    Autotune.purge_messages
  end

  test 'send message' do
    Autotune.send_message('ping', 'pong')
    Autotune.send_message('ping', 'pong')

    assert_equal 2, Autotune.messages.length, 'Should have two messages'
  end

  test 'can message' do
    assert Autotune.can_message?
  end

  test 'pub sub messages' do
    finished = false

    # TODO: make this work instead of the mess below
    # Autotune.on_message do |type, message|
    #   assert_equal 'ping', type, 'Message type should be ping'
    #   assert_equal 'pong', message, 'Message should be pong'
    #   finished = true
    # end

    redis_thread = Thread.new do
      Thread.current.abort_on_exception = true
      Autotune.redis_sub.subscribe('ping') do |on|
        on.message do |channel, msg|
          assert_equal 'ping', channel, 'Message type should be ping'
          assert_equal 'pong', ActiveSupport::JSON.decode(msg), 'Message should be pong'
          finished = true
        end
      end
    end

    sleep 1.second
    Autotune.send_message('ping', 'pong')

    counter = 0
    loop do
      if finished || counter > 10
        # Autotune.cancel_subscription
        if redis_thread.alive?
          redis_thread.exit
          Autotune.redis_sub.quit
        end
      end

      flunk('Failed to recieve message') if counter > 10

      if finished
        pass
        break
      end

      counter += 1
      sleep 1.second
    end
  end

  test 'get message since' do
    Autotune.send_message('ping', 'pong')
    Autotune.send_message('ping', 'pong')
    sleep 2
    now = DateTime.current
    Autotune.send_message('ping', 'pong')
    Autotune.send_message('ping', 'pong')

    assert_raises do
      Autotune.messages(:since => now.utc.to_i)
    end
    assert_equal 2, Autotune.messages(:since => now).length,
                 'Should have two messages'
  end

  test 'query messages' do
    Autotune.send_message('ping', 'pong')
    Autotune.send_message('ping', 'pong')
    Autotune.send_message('foo', 'pong')

    assert_equal 2, Autotune.messages(:type => 'ping').length,
                 'Should have two messages'
  end

  test 'clean up messages' do
    Autotune.send_message('ping', 'pong')
    Autotune.send_message('ping', 'pong')
    sleep 2
    now = DateTime.current
    Autotune.send_message('ping', 'pong')
    Autotune.send_message('ping', 'pong')

    assert_equal 4, Autotune.messages.length, 'Should have four messages'

    assert_raises do
      Autotune.purge_messages(:older_than => now.utc.to_i)
    end
    Autotune.purge_messages(:older_than => now)

    assert_equal 2, Autotune.messages.length, 'Should have no messages'
  end
end
