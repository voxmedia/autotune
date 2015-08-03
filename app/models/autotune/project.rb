require 'redis'

module Autotune
  # Blueprints get built
  class Project < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    serialize :data, JSON
    serialize :meta, JSON
    serialize :blueprint_config, JSON
    belongs_to :blueprint
    belongs_to :user
    belongs_to :theme

    validates :title, :blueprint, :user, :theme, :presence => true
    validates :status,
              :inclusion => { :in => Autotune::PROJECT_STATUSES }
    before_validation :defaults

    default_scope { order('updated_at DESC') }

    search_fields :title

    before_save :check_for_updated_data

    after_save :pub_to_redis

    after_initialize do
      self.status ||= 'new'
      self.meta   ||= {}
    end

    def draft?
      published_at.nil?
    end

    def published?
      !draft?
    end

    def unpublished_updates?
      published? && published_at < data_updated_at
    end

    def update_snapshot
      if blueprint_version == blueprint.version
        update!(:status => 'building')
      else
        update!(
          :status => 'building',
          :blueprint_version => blueprint.version,
          :blueprint_config => blueprint.config)
      end
      BuildJob.perform_later(self, :preview, true)
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
      BuildJob.perform_later(self, :publish)
    rescue
      update!(:status => 'broken')
      raise
    end

    def deploy_dir
      File.join(working_dir, blueprint_config['deploy_dir'] || 'build')
    end

    def preview_url
      Autotune.find_deployment(:preview).url_for(self, slug)
    end

    def publish_url
      Autotune.find_deployment(:preview).url_for(self, slug)
    end

    private

    def defaults
      # self.data ||= {}  # seems to mess up check_for_updated_data
      self.blueprint_version ||= blueprint.version unless blueprint.nil?
      self.blueprint_config ||= blueprint.config unless blueprint.nil?
    end

    def check_for_updated_data
      self.data_updated_at = DateTime.current if data_changed?
    end

    def pub_to_redis
      return if Autotune.redis_pub.nil?
      msg = { :id => id,
              :status => status }
      Autotune.redis_pub.publish 'project', msg.to_json
    end
  end
end
