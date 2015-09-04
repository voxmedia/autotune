module ActiveJob
  module Chaining
    extend ActiveSupport::Concern

    included do
      after_perform :if => :next_job do |job|
        unless job.skip_next_job
          Rails.logger.debug 'enqueue next job!'
          job.next_job.enqueue
          Rails.cache.delete(job.next_job_key)
        end
        true
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

    def then(job)
      self.next_job = job
    end

    def next_job=(job)
      Rails.cache.write(
        next_job_key, job.serialize, :expires_in => 1.day)
      @next_job = job
    end

    def next_job
      @next_job ||=
        if Rails.cache.exist?(next_job_key)
          ActiveJob::Base.deserialize(
            Rails.cache.read(next_job_key))
        else
          nil
        end
    end

    def next_job_key
      "next_job:#{job_id}"
    end
  end

  Base.send :include, Chaining
end
