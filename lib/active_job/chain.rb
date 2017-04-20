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

    def enqueue(opts = {})
      return self if jobs.blank?

      first_job, fail_job = jobs.first
      first_job.catch(fail_job) if fail_job

      # Loop over all jobs in this chain and connect the job using the `then`
      # method from the chaining mixin. Only loop if we have more than one to
      # actually chain together
      if jobs.size > 1
        # we're gonna loop starting with the second job, so setup `prev_job`
        # with the first job in the chain
        prev_job = first_job
        jobs[1..-1].each do |success, failure|
          next if success.nil?
          prev_job = prev_job.then(success, failure)
          prev_job.queue_name = opts[:queue_name] if opts[:queue_name].present?
          prev_job.priority = opts[:priority] if opts[:priority].present?
        end
      end

      first_job.enqueue(opts)

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

    # Return a list of pairs of the jobs in this chain. Each pair has a job
    # to run if the previous job completed successfully, and one to run if it
    # failed.
    def jobs
      fjob = nil
      # We iterate over the list backwards so we can fill in failure jobs that
      # were specified in a later `then` or `catch` statement.
      @jobs.reverse.map do |job|
        fjob = job.last if job.last
        [job.first, fjob]
      end.reverse
    end
  end
end
