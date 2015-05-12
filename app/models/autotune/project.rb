require 'redis'

module Autotune
  # Blueprints get built
  class Project < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    serialize :data, Hash
    serialize :blueprint_config, Hash
    belongs_to :blueprint
    belongs_to :user

    validates :title, :blueprint, :user, :presence => true
    validates :status,
              :inclusion => { :in => Autotune::PROJECT_STATUSES }
    before_validation :defaults

    default_scope { order('updated_at DESC') }

    search_fields :title

    after_save :pub_to_redis

    def update_snapshot
      return if blueprint_version == blueprint.version
      update!(
        :status => 'building',
        :blueprint_version => blueprint.version,
        :blueprint_config => blueprint.config)
      BuildJob.perform_later(self, 'preview', true)
    rescue
      update!(:status => 'broken')
      raise
    end

    def build
      update(:status => 'building')
      BuildJob.perform_later(self)
    rescue
      update!(:status => 'broken')
      raise
    end

    def build_and_publish
      update(:status => 'building')
      BuildJob.perform_later(self, 'publish')
    rescue
      update!(:status => 'broken')
      raise
    end

    def preview_url
      return nil if Rails.configuration.autotune.preview.empty?
      File.join(Rails.configuration.autotune.preview[:base_url], slug).to_s + '/'
    end

    def publish_url
      return nil if Rails.configuration.autotune.publish.empty?
      File.join(Rails.configuration.autotune.publish[:base_url], slug).to_s + '/'
    end

    private

    def defaults
      self.status ||= 'new'
      self.theme ||= 'default'
      self.blueprint_version ||= blueprint.version unless blueprint.nil?
      self.blueprint_config ||= blueprint.config unless blueprint.nil?
    end

    def pub_to_redis
      return if $redis.nil?
      msg = { id: id,
              status: status }
      $redis.publish 'projects', msg.to_json
    end
  end
end
