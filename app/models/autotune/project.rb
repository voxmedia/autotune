require 'snapshot'

module Autotune
  # Blueprints get built
  class Project < ActiveRecord::Base
    include Slugged
    serialize :data, Hash
    belongs_to :blueprint

    validates :title, :blueprint, :presence => true
    validates :status,
              :inclusion => { :in => %w(new updating updated building built broken) }
    before_validation :defaults

    def working_dir
      File.join(Rails.configuration.projects_dir, slug)
    end

    def update_snapshot
      update(:status => 'updating')
      SyncProjectJob.perform_later(self)
    end

    def build
      update(:status => 'building')
      BuildJob.perform_later(self)
    end

    # only call these from a job

    def snapshot
      @snapshot ||= Snapshot.new working_dir
    end

    def sync_snapshot
      snapshot.sync(blueprint.repo)
      update(:blueprint_version => blueprint.version)
    end

    private

    def defaults
      self.status ||= 'new'
      self.theme ||= 'default'
    end
  end
end
