module ActiveJob
  module Unique
    extend ActiveSupport::Concern

    included do
      delegate :unique_key_callback, :unique_ttl, :to => :class

      around_enqueue :if => :unique_key do |job, block|
        if Rails.cache.exist?(unique_key)
          Rails.logger.debug 'existing unique job, cancel enqueue'
          false
        else
          Rails.logger.debug 'enqueue unique job'
          Rails.cache.write(unique_key, job_id, :expired_in => unique_ttl)
          block.call
        end
      end

      around_perform :if => :unique_key do |job, block|
        if !Rails.cache.exist?(unique_key) ||
           Rails.cache.read(unique_key) == job_id
          Rails.logger.debug 'perform unique job'
          Rails.cache.delete(unique_key)
          block.call
        else
          Rails.logger.debug 'existing unique job, canceling perform'
          false
        end
      end
    end

    class_methods do
      def unique_job(**opts, &block)
        @unique_ttl = opts[:ttl] || 10.minutes
        @unique_key_callback = block
      end
      attr_reader :unique_key_callback, :unique_ttl
    end

    def unique_key
      @unique_key ||=
        if unique_key_callback.is_a? Proc
          deserialize_arguments_if_needed
          instance_eval(&unique_key_callback)
        else
          nil
        end
    end
  end

  Base.send :include, Unique
end
