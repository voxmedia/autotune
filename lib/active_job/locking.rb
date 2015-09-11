module ActiveJob
  module Locking
    extend ActiveSupport::Concern

    included do
      delegate :lock_key_callback, :lock_ttl, :lock_retry, :to => :class

      around_perform :if => :lock_key do |_job, block|
        lock_info = Autotune.lock(lock_key, lock_ttl)
        if lock_info
          logger.debug 'Obtained lock'
          ret = block.call
          Autotune.unlock(lock_info)
          logger.debug 'Released lock'
          ret
        else
          logger.debug 'Failed to obtain lock, retry job'
          if lock_retry
            retry_job :wait => lock_retry
          else
            retry_job
          end
          false
        end
      end
    end

    class_methods do
      def lock_job(**opts, &block)
        @lock_ttl = opts[:ttl] || 10.minutes
        @lock_retry = opts[:retry] || nil
        @lock_key_callback = block
      end
      attr_reader :lock_key_callback, :lock_ttl, :lock_retry
    end

    def lock_key
      @lock_key ||=
        if lock_key_callback.is_a? Proc
          deserialize_arguments_if_needed
          instance_eval(&lock_key_callback)
        else
          nil
        end
    end
  end

  Base.send :include, Locking
end
