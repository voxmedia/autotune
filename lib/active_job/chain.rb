module ActiveJob
  class Chain
    def initialize(*args)
      @jobs = args.map do |job|
        if job.is_a? Array
          job
        else
          [job, nil]
        end
      end
      self
    end

    def then(success, failure = nil)
      @jobs << [success, failure]
      self
    end

    def catch(failure)
      @jobs << [nil, failure]
      self
    end

    def enqueue(options = {})
      return self if jobs.nil?

      first_job, fail_job = jobs.first
      first_job.catch(fail_job) if fail_job

      prev_job = first_job
      jobs[1..-1].each do |success, failure|
        next if success.nil?
        prev_job = prev_job.then(success, failure)
      end

      first_job.enqueue(options)

      self
    end

    def perform_now
      jobs.each do |success_job, fail_job|
        begin
          success_job.perform_now
        rescue
          fail_job.perform_now
          break
        end
      end

      self
    end

    def jobs
      fjob = nil
      @jobs.reverse.map do |job|
        fjob = job.last if job.last
        [job.first, fjob]
      end.reverse
    end
  end
end
