module ActiveJob
  module Locking
    extend ActiveSupport::Concern

    included do
      delegate :lock_key_callback, :lock_ttl, :lock_retry, :to => :class

      around_perform :if => :lock_key do |_job, block|
        if Rails.cache.exist?(lock_key)
          logger.debug "Retry job; Lock failed #{lock_key}"
          if lock_retry
            retry_job :wait => lock_retry
          else
            retry_job
          end
          false
        else
          logger.debug "Obtained lock #{lock_key}"
          Rails.cache.write(lock_key, job_id, :expired_in => lock_ttl)
          ret = nil
          begin
            ret = block.call
          ensure
            Rails.cache.delete(lock_key)
            logger.debug "Released lock #{lock_key}"
          end
          ret
        end
      end
    end

    class_methods do
      def lock_job(**opts, &block)
        @lock_ttl = opts[:ttl] || 10.minutes
        @lock_retry = opts[:retry] || nil
        @lock_key_callback = block_given? ? block : opts[:with]
      end
      attr_reader :lock_key_callback, :lock_ttl, :lock_retry
    end

    def lock_key
      @lock_key ||=
        if lock_key_callback.is_a? Proc
          deserialize_arguments_if_needed
          "lock:#{Digest::SHA1.hexdigest(instance_eval(&lock_key_callback).to_s)}"
        elsif lock_key_callback == :payload
          deserialize_arguments_if_needed
          "lock:#{Digest::SHA1.hexdigest(arguments.serialize.to_s)}"
        else
          nil
        end
    end
  end

  Base.send :include, Locking
end
