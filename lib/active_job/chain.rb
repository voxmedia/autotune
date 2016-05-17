module ActiveJob
  class Chain
    @jobs = []
    attr_accessor :jobs

    def initialize(*args)
      self.jobs = args if args.any?
    end

    def enqueue(options = {})
      return self if jobs.nil?

      prev_job = jobs.first
      jobs.each do |job|
        next if job == jobs.first
        prev_job = prev_job.then(job)
      end
      jobs.first.enqueue(options)

      self
    end

    def perform_now
      jobs.each do |job|
        job.perform_now
      end

      self
    end
  end
end
