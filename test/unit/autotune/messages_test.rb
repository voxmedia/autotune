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
