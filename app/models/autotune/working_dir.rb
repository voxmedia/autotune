module Autotune
  # Handle stuff around having a slug on a model
  module WorkingDir
    extend ActiveSupport::Concern

    included do
      after_save :move_working_dir
    end

    def working_dir
      File.join(Rails.configuration.autotune.projects_dir, slug).to_s
    end

    def working_dir_was
      return if !slug_changed? || slug_was.nil?
      File.join(Rails.configuration.autotune.projects_dir, slug_was).to_s
    end

    private

    def move_working_dir
      return if !slug_changed? || slug_was.nil?
      MoveWorkDirJob.perform_later(working_dir_was, working_dir)
    end
  end
end
