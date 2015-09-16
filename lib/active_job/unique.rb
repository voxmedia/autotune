module ActiveJob
  module Unique
    extend ActiveSupport::Concern

    included do
      delegate :unique_key_callback, :unique_ttl, :to => :class

      around_enqueue :if => :unique_key do |job, block|
        logger.debug "Unique with #{unique_key}"
        if Rails.cache.exist?(unique_key)
          logger.debug(
            "Existing unique #{job.class}, cancel enqueue")
          false
        else
          logger.debug("Enqueue unique #{job.class}")
          Rails.cache.write(unique_key, job_id, :expired_in => unique_ttl)
          block.call
        end
      end

      around_perform :if => :unique_key do |job, block|
        if !Rails.cache.exist?(unique_key) ||
           Rails.cache.read(unique_key) == job_id
          logger.debug("Perform unique #{job.class}")
          Rails.cache.delete(unique_key)
          block.call
        else
          logger.debug("Existing unique #{job.class}, cancel perform")
          false
        end
      end
    end

    class_methods do
      def unique_job(**opts, &block)
        @unique_ttl = opts[:ttl] || 10.minutes
        @unique_key_callback = block_given? ? block : opts[:with]
      end
      attr_reader :unique_key_callback, :unique_ttl
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
