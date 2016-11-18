require 'test_helper'

module Autotune
  # Testing for messages
  class MessagesControllerTest < ActionController::TestCase
    fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes', 'autotune/groups'
    setup do
      skip 'Cannot run tests without Redis' if Autotune.redis.nil?
      Autotune.purge_messages
    end

    test 'should require authentication' do
      accept_json!

      get :index
      assert_response :unauthorized
      assert_equal({ 'error' => 'Unauthorized' }, decoded_response)
    end

    test 'should get messages' do
      accept_json!
      valid_auth_header!

      num_messages = 30

      # Send twice as many messages as we want to test for
      num_messages.times { Autotune.send_message('ping', 'pong') }
      current_dt = DateTime.current
      num_messages.times { Autotune.send_message('ping', 'pong') }

      # To test the since function, make sure we only recieve half of the
      # messages we created
      get :index, :since => current_dt.to_f + Autotune::MESSAGE_BUFFER
      assert_response :success
      assert_instance_of Array, decoded_response,
                         'Should have an array of messages'
      assert_equal num_messages, decoded_response.length,
                   "Should have #{num_messages} messages"
    end

    test 'should handle different date formats' do
      accept_json!
      valid_auth_header!

      num_messages = 30

      # Send twice as many messages as we want to test for
      num_messages.times { Autotune.send_message('ping', 'pong') }
      sleep 2
      dt = DateTime.current
      sleep 2
      num_messages.times { Autotune.send_message('ping', 'pong') }

      # To test the since function, make sure we only recieve half of the
      # messages we created. Test with a bunch of date formats
      [:to_f, :to_i, :iso8601, :rfc3339, :jisx0301].each do |meth|
        get :index, :since => dt.send(meth)
        assert_response :success
        assert_instance_of Array, decoded_response,
                           "Should have an array of messages from request with #{meth} format"
        assert_equal num_messages, decoded_response.length,
                     "Should have #{num_messages} messages from request with #{meth} format"
      end
    end

    test 'should get messages by type' do
      accept_json!
      valid_auth_header!

      # Send twice as many messages as we want to test for
      Autotune.send_message('ping', 'pong')
      Autotune.send_message('foo', 'bar')
      current_dt = DateTime.current
      Autotune.send_message('ping', 'pong')
      Autotune.send_message('foo', 'bar')

      # To test the since function, make sure we only recieve half of the
      # messages we created
      get :index, :since => current_dt.to_f + Autotune::MESSAGE_BUFFER, :type => 'foo'
      assert_response :success
      assert_instance_of Array, decoded_response,
                         'Should have an array of messages'
      assert_equal 1, decoded_response.length,
                   'Should have 1 message'
    end

    test 'should send message' do
      accept_json!
      valid_auth_header!

      post :send_message, :type => 'ping', :message => 'pong'
      assert_response :accepted
    end

    test 'updating a project should create a message' do
      accept_json!
      valid_auth_header!

      current_dt = DateTime.current
      p = autotune_projects(:example_one)
      p.update!(:status => 'building')

      get :index, :since => current_dt.to_f + Autotune::MESSAGE_BUFFER
      assert_response :success
      assert_instance_of Array, decoded_response,
                         'Should have an array of messages'
      assert_equal 1, decoded_response.length,
                   'Should have 1 message'
    end

    test 'updating a blueprint should create a message' do
      accept_json!
      valid_auth_header!

      current_dt = DateTime.current
      b = autotune_blueprints(:example)
      b.update!(:status => 'built')

      get :index, :since => current_dt.to_f + Autotune::MESSAGE_BUFFER
      assert_response :success
      assert_instance_of Array, decoded_response,
                         'Should have an array of messages'
      assert_equal 1, decoded_response.length,
                   'Should have 1 message'
    end
  end
end
