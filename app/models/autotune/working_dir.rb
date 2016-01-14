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

    private

    def move_working_dir
      return if !slug_changed? || slug_was.nil? || slug == slug_was
      MoveWorkDirJob.perform_later(working_dir_was, working_dir)
    end

    def delete_working_dir
      DeleteWorkDirJob.perform_later(working_dir)
    end
  end
end
