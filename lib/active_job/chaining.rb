module ActiveJob
  module Chaining
    extend ActiveSupport::Concern

    included do
      around_perform :if => :chained? do |job, block|
        begin
          block.call
          job.enqueue_success
        rescue
          job.enqueue_fail
          raise
        end
      end
    end

    attr_accessor :skip_next_job

    def break_chain
      self.skip_next_job = true
    end

    def retry_job(options = {})
      self.skip_next_job = true
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
      unless skip_next_job
        logger.debug("Enqueue next: #{success_job.class}")
        success_job.enqueue
        clear_keys
      end
    end

    def enqueue_fail
      unless skip_next_job
        logger.debug("Enqueue next: #{fail_job.class}")
        success_job.enqueue
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

    def cache_job(type, job)
      Rails.cache.write(
        job_key(type), job.serialize, :expires_in => 1.day)
      job
    end

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
