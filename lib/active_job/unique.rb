module ActiveJob
  module Unique
    extend ActiveSupport::Concern

    included do
      delegate :unique_key_callback, :unique_ttl, :to => :class

      around_enqueue :if => :unique_key do |job, block|
        if (scheduled_at - Time.now.to_f) >= scheduled_unique_threshold
          block.call
        elsif Rails.cache.exist?(unique_key)
          logger.debug("Cancel enqueue; Existing unique #{unique_key}")
          if respond_to?(:chained?) && chained?
            # if this job is part of a chain, enqueue the next job
            job.enqueue_success(:wait_until => scheduled_at)
          end
          false
        else
          logger.debug("Enqueue unique #{unique_key}")
          Rails.cache.write(unique_key, job_id, :expired_in => unique_ttl)
          block.call
        end
      end

      around_perform :if => :unique_key do |_job, block|
        if !Rails.cache.exist?(unique_key) ||
           Rails.cache.read(unique_key) == job_id
          logger.debug("Perform unique #{unique_key}")
          Rails.cache.delete(unique_key)
          block.call
        else
          logger.debug("Cancel perform; Existing unique #{unique_key}")
          if respond_to?(:chained?) && chained?
            # if this job is part of a chain, enqueue the next job
            job.enqueue_success(:wait_until => scheduled_at)
          end
          false
        end
      end
    end

    class_methods do
      def unique_job(**opts, &block)
        @unique_ttl = opts[:ttl] || 10.minutes
        @unique_key_callback = block_given? ? block : opts[:with]
        @scheduled_unique_threshold = opts[:scheduled_thresold] || 1.minute
      end
      attr_reader :unique_key_callback, :unique_ttl, :scheduled_unique_threshold
    end

    def unique_key
      @unique_key ||=
        if unique_key_callback.is_a? Proc
          deserialize_arguments_if_needed
          "unique:#{Digest::SHA1.hexdigest(instance_eval(&unique_key_callback).to_s)}"
        elsif unique_key_callback == :payload
          deserialize_arguments_if_needed
          "unique:#{Digest::SHA1.hexdigest(serialize_arguments(arguments).to_s)}"
        else
          nil
        end
    end
  end

  Base.send :include, Unique
end
