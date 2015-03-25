require 'work_dir'

module Autotune
  # Blueprints get built
  class Project < ActiveRecord::Base
    include Slugged
    include Searchable
    serialize :data, Hash
    belongs_to :blueprint

    validates :title, :blueprint, :presence => true
    validates :status,
              :inclusion => { :in => Autotune::PROJECT_STATUSES }
    before_validation :defaults

    search_fields :title

    def working_dir
      File.join(Rails.configuration.autotune.projects_dir, slug)
    end

    def update_snapshot
      update(:status => 'updating')
      SyncProjectJob.perform_later(self)
    end

    def build
      update(:status => 'building')
      BuildJob.perform_later(self)
    end

    private

    def defaults
      self.status ||= 'new'
      self.theme ||= 'default'
      self.blueprint_version ||= blueprint.version unless blueprint.nil?
    end
  end
end
