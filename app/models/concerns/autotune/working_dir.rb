module Autotune
  # Handle stuff around having a slug on a model
  module WorkingDir
    extend ActiveSupport::Concern

    included do
      after_save :move_working_dir, :if => :installed?
      after_destroy :delete_working_dir, :if => :installed?
    end

    def installed?
      true
    end

    def working_dir
      File.join(
        Autotune.config.working_dir,
        self.class.model_name.element.pluralize,
        slug).to_s
    end

    def working_dir_was
      return if !slug_changed? || slug_was.nil?
      File.join(
        Autotune.config.working_dir,
        self.class.model_name.element.pluralize,
        slug_was).to_s
    end

    def new_shell(**kwargs)
      kwargs[:logger] ||= output_logger if defined?(output_logger)
      repo = Autoshell.new(working_dir, **kwargs)
      repo.logger.formatter = proc do |severity, datetime, _progname, msg|
        "#{datetime.strftime('%b %e %H:%M %Z')}\t#{severity}\t#{msg}\n"
      end
      repo
    end

    def setup_shell(**kwargs)
      @setup_shell ||= new_shell(:env => Autotune.configuration.setup_environment, **kwargs)
    end

    def build_shell(**kwargs)
      @build_shell ||= new_shell(:env => Autotune.configuration.build_environment, **kwargs)
    end

    # Creates a lock entry for the working_dir in the cache.
    # @return [Boolean] True if a lock was created
    def file_lock!
      raise "Can't obtain lock #{file_lock_key}" if file_lock?
      logger.debug "Obtained lock #{file_lock_key}"
      Rails.cache.write(file_lock_key, id)
    end

    # Check if there is a lock entry for this working_dir
    # @return [Boolean] True if a lock exists
    def file_lock?
      Rails.cache.exist?(file_lock_key)
    end

    # Release the lock for this working_dir
    # @return [Boolean] True if the lock was deleted
    def file_unlock!
      logger.debug "Released lock #{file_lock_key}"
      Rails.cache.delete(file_lock_key)
    end

    # Obtain file lock and execute given block and remove lock
    def with_file_lock
      file_lock!
      yield self
    ensure
      file_unlock!
    end

    def file_lock_key
      "filelock:#{working_dir}"
    end

    private

    def move_working_dir
      return if !slug_changed? || slug_was.blank? || slug == slug_was
      MoveWorkDirJob.perform_later(working_dir_was, working_dir)
    end

    def delete_working_dir
      DeleteWorkDirJob.perform_later(working_dir)
    end
  end
end
