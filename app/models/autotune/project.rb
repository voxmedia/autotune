require 'redis'

module Autotune
  # Blueprints get built
  class Project < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    include Deployable
    serialize :data, JSON
    serialize :meta, JSON
    serialize :blueprint_config, JSON
    belongs_to :blueprint
    belongs_to :user
    belongs_to :theme

    validates :title, :blueprint, :user, :theme, :presence => true
    validates :status,
              :inclusion => { :in => Autotune::PROJECT_STATUSES }

    default_scope { order('updated_at DESC') }

    search_fields :title

    before_save :check_for_updated_data

    after_save :pub_to_redis

    after_initialize do
      self.status ||= 'new'
      self.meta   ||= {}
    end

    before_validation do
      # Make sure our slug includes the theme
      if theme && (theme_changed? || slug_changed?)
        self.slug = self.class.unique_slug(theme.value + '-' + slug_sans_theme, id)
      end

      # Make sure we stash version and config
      self.blueprint_version ||= blueprint.version unless blueprint.nil?
      self.blueprint_config  ||= blueprint.config unless blueprint.nil?
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
      ActiveJob::Chain.new(
        SyncBlueprintJob.new(blueprint),
        SyncProjectJob.new(self, :update => true),
        BuildJob.new(self)
      ).enqueue
    rescue
      update!(:status => 'broken')
      raise
    end

    def build
      update(:status => 'building')
      ActiveJob::Chain.new(
        SyncBlueprintJob.new(blueprint),
        SyncProjectJob.new(self),
        BuildJob.new(self)
      ).enqueue
    rescue
      update!(:status => 'broken')
      raise
    end

    def build_and_publish
      update(:status => 'building')
      ActiveJob::Chain.new(
        SyncBlueprintJob.new(blueprint),
        SyncProjectJob.new(self),
        BuildJob.new(self, :target => 'publish')
      ).enqueue
    rescue
      update!(:status => 'broken')
      raise
    end

    def deploy_dir
      File.join(working_dir, blueprint_config['deploy_dir'] || 'build')
    end

    def preview_url
      @preview_url ||= deployer(:preview).project_url
    end

    def publish_url
      @publish_url ||= deployer(:publish).project_url
    end

    def slug_sans_theme
      if theme_changed? && theme_was
        slug.sub(/^(#{theme.value}|#{theme_was.value})-/, '')
      else
        slug.sub(/^#{theme.value}-/, '')
      end
    end

    def theme_was
      return @theme_was if @theme_was && @theme_was.id == theme_id_was
      @theme_was = theme_id_was.nil? ? nil : Theme.find(theme_id_was)
    end

    def theme_changed?
      theme_id_changed?
    end

    private

    def check_for_updated_data
      self.data_updated_at = DateTime.current if data_changed?
    end

    def pub_to_redis
      return if Autotune.redis.nil?
      msg = { :id => id,
              :status => status }
      Autotune.redis.publish 'project', msg.to_json
    end
  end
end
