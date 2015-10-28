require 'test_helper'

module Autotune
  class LogTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints', 'autotune/projects'

    test 'should validate stuff' do
      # missing everything
      assert_raises ActiveRecord::RecordInvalid do
        Log.create!
      end

      l = Log.new
      # Default created and logger available
      assert_operator l.created_at, :<=, Time.zone.now
      assert_operator l.logger, :is_a?, Logger

      # Content and time is nil
      assert_nil l.content
      assert_nil l.time

      # missing blueprint and label
      assert_raises ActiveRecord::RecordInvalid do
        l.save!
      end

      # Content is empty
      assert_empty l.content
      # Time elapsed is greater than 0
      assert_operator l.time, :>, 0
      last_time = l.time

      # add blueprint and a message
      l.blueprint = autotune_blueprints :example
      l.info('test log')

      # missing label
      assert_raises ActiveRecord::RecordInvalid do
        l.save!
      end

      # Content isn't empty
      assert_match /test log/, l.content
      # Time elapsed is greater than 0
      assert_operator l.time, :>, last_time
      last_time = l.time

      l.error('test error')

      # missing label, still
      assert_raises ActiveRecord::RecordInvalid do
        l.save!
      end

      # Content isn't empty
      assert_match(/test log/, l.content)
      assert_match(/test error/, l.content)
      # Time elapsed is greater than 0
      assert_operator l.time, :>, last_time
      last_time = l.time

      l.label = 'test'

      assert l.save

      # Content isn't empty
      assert_match(/test log/, l.content)
      assert_match(/test error/, l.content)
      # Time elapsed is greater than 0
      assert_operator l.time, :>, last_time
    end

    test 'cant change log after creation' do
      l = Log.new(
        :label => 'test',
        :blueprint => autotune_blueprints(:example))
      l.info('test info')

      assert l.save
      assert_raises { l.info('cant do this') }
    end

    test 'cant save empty log' do
      l = Log.new(
        :label => 'test',
        :project => autotune_projects(:example_one))

      assert_raises(ActiveRecord::RecordInvalid) { l.save! }
    end

    test 'can attach to project' do
      l = Log.new(
        :label => 'test',
        :project => autotune_projects(:example_one))
      l.info('test info')

      assert l.save, l.errors.full_messages.join(', ')
    end

    test 'second save doesnt change anything' do
      l = Log.new(
        :label => 'test',
        :project => autotune_projects(:example_one))
      l.info('test info')

      assert l.save, l.errors.full_messages.join(', ')
      time = l.time
      content = l.content
      created = l.created_at
      label = l.label

      assert l.save, l.errors.full_messages.join(', ')

      assert_equal time, l.time
      assert_equal content, l.content
      assert_equal created, l.created_at
      assert_equal label, l.label
    end
  end
end
