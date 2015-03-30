module Autotune
  # Blueprints get built
  class Project < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    serialize :data, Hash
    belongs_to :blueprint

    validates :title, :blueprint, :presence => true
    validates :status,
              :inclusion => { :in => Autotune::PROJECT_STATUSES }
    before_validation :defaults

    search_fields :title

    def update_snapshot
      update(:status => 'updating')
      SyncProjectJob.perform_later(self)
    end

    def build
      update(:status => 'building')
      BuildJob.perform_later(self)
    end

    def preview_url
      File.join(Rails.configuration.autotune.preview[:base_url], slug).to_s
    end

    def publish_url
      File.join(Rails.configuration.autotune.publish[:base_url], slug).to_s
    end

    private

    def defaults
      self.status ||= 'new'
      self.theme ||= 'default'
      self.blueprint_version ||= blueprint.version unless blueprint.nil?
    end
  end
end
