module ActiveJob
  module Chaining
    extend ActiveSupport::Concern

    included do
      attr_accessor :cache_ttl_buffer
      around_perform :if => :chained? do |job, block|
        begin
          block.call
          job.enqueue_success
        rescue => e
          job.enqueue_fail
          logger.error e.message
          logger.error e.backtrace.join("\n")
          raise
        end
      end
    end

    def skip_next_job!
      @skip_next_job = true
    end
    alias_method :break_chain!, :skip_next_job!

    def skip_next_job?
      return @skip_next_job if defined? @skip_next_job
      @skip_next_job = false
    end

    def retry_job(options = {})
      @skip_next_job = true
      super
    end

    def enqueue(options = {})
      deserialize_arguments_if_needed
      super
    end

    def then(success, failure = nil)
      self.fail_job = failure if failure
      self.success_job = success
    end

    def catch(failure)
      self.fail_job = failure
      self
    end

    def success_job=(job)
      @success_job = cache_job('success', job)
    end

    def success_job
      @success_job ||= read_cache_job('success')
    end

    def fail_job=(job)
      @fail_job = cache_job('fail', job)
    end

    def fail_job
      @fail_job ||= read_cache_job('fail')
    end

    def enqueue_success
      unless skip_next_job?
        logger.debug("Enqueue next: #{success_job.class}")
        success_job.enqueue
        clear_keys
      end
    end

    def enqueue_fail
      unless skip_next_job?
        logger.debug("Enqueue fail job: #{fail_job.class}")
        fail_job.enqueue
        clear_keys
      end
    end

    def chained?
      success_job || fail_job
    end

    private

    def clear_keys
      Rails.cache.delete(job_key('succcess'))
      Rails.cache.delete(job_key('fail'))
    end

    # Cache the deets of the success and error jobs to call after this one
    def cache_job(type, job)
      # since we set a cache item ttl, we have to make sure that the cache key
      # doesn't time out before it's needed. Setting a 24hour ttl is fine for
      # most jobs, but its a problem if the job is scheduled a day out.
      # Here we use a value to buffer the ttl based on the scheduled time, and
      # pass it along to other jobs which might have more chained methods.
      if cache_ttl_buffer.nil?
        self.cache_ttl_buffer = scheduled_at.present? ? scheduled_at - Time.now.to_f : 0
      end
      job.cache_ttl_buffer = cache_ttl_buffer
      Rails.cache.write(
        job_key(type), job.serialize, :expires_in => cache_ttl_buffer + 1.day)
      job
    end

    # Get the cached job object for the success or fail type
    def read_cache_job(type)
      if Rails.cache.exist?(job_key(type))
        ActiveJob::Base.deserialize(
          Rails.cache.read(job_key(type)))
      end
    end

    def job_key(type)
      "chain_#{type}:#{job_id}"
    end
  end

  Base.send :include, Chaining
end
