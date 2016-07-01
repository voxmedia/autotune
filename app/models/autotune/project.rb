require 'redis'

module Autotune
  # Model for Autotune projects.
  # A project is blueprint with data.
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
    belongs_to :group

    validates_length_of :output, :maximum => 64.kilobytes - 1
    validates :title, :blueprint, :user, :group, :theme, :presence => true
    validates :status,
              :inclusion => { :in => Autotune::PROJECT_STATUSES }

    default_scope { order('updated_at DESC') }

    search_fields :title

    before_save :check_for_updated_data

    after_save :pub_to_redis

    after_initialize do
      self.status ||= 'new'
      self.meta ||= {}
    end

    before_validation do
      # Make sure our slug includes the theme
      if theme && (theme_changed? || slug_changed?)
        self.slug = self.class.unique_slug(theme.slug + '-' + slug_sans_theme, id)
      end

      # Truncate output field so we can save without error
      omission = '... (truncated)'
      output_limit = 60.kilobytes
      if output.present? && output.length > output_limit
        # Don't trust String#truncate
        self.output = output[0, output_limit - omission.length] + omission
      end

      # Make sure we stash version and config
      self.blueprint_version ||= blueprint.version unless blueprint.nil?
      self.blueprint_config ||= blueprint.config unless blueprint.nil?
    end

    # Checks if the project is a draft. i.e. not published.
    # @return [Boolean] `true` if the project is in `draft` status, `false` otherwise.
    def draft?
      published_at.nil?
    end

    # Checks if the project is published.
    # @return [Boolean] `true` if the project is published, `false` otherwise.
    def published?
      !draft?
    end

    # Checks if the project has unpublished updates.
    # @return [Boolean] `true` if the project has unpublished updates, `false` otherwise.
    def unpublished_updates?
      published? && published_at < data_updated_at
    end

    # Checks if the project is ready for publish.
    # @return [Boolean] `true` if the project is ready for publish, `false` otherwise.
    def publishable?
      draft? || unpublished_updates?
    end

    # Checks if the project supports live preview
    # @return [Boolean] `true` if the project supports live preview, `false` otherwise.
    def live?
      blueprint_config.present? && blueprint_config['preview_type'] == 'live'
    end

    # Updates blueprint version and builds the project.
    # Queues jobs to sync latest verison of blueprint, update it on the project
    # and build the new project.
    # It publishes updates on projects already published.
    # @raise The original exception when the update fails
    # @see build
    # @see build_and_publish
    def update_snapshot(current_user = nil)
      if blueprint_version == blueprint.version
        update!(:status => 'building')
      else
        update!(
          :status => 'building',
          :blueprint_version => blueprint.version,
          :blueprint_config => blueprint.config)
      end
      ActiveJob::Chain.new(
        SyncBlueprintJob.new(blueprint, :current_user => current_user),
        SyncProjectJob.new(self, :update => true),
        BuildJob.new(
          self,
          :target => publishable? ? 'preview' : 'publish',
          :current_user => current_user
        )
      ).catch(SetStatusJob.new(self, 'broken')).enqueue
    rescue
      update!(:status => 'broken')
      raise
    end

    # Updates blueprint version and builds the project.
    # Queues jobs to sync latest verison of blueprint, update it on the project
    # and build the new project.
    # It publishes updates on projects already published.
    # @raise The original exception when the update fails
    # @see build_and_publish
    # @see update_snapshot
    def build(current_user = nil)
      update(:status => 'building')
      ActiveJob::Chain.new(
        SyncBlueprintJob.new(blueprint, :current_user => current_user),
        SyncProjectJob.new(self),
        BuildJob.new(
          self,
          :target => publishable? ? 'preview' : 'publish',
          :current_user => current_user
        )
      ).catch(SetStatusJob.new(self, 'broken')).enqueue
    rescue
      update!(:status => 'broken')
      raise
    end

    # Builds and publishes the project.
    # Updates blueprint version and builds the project.
    # Queues jobs to sync latest verison of blueprint, update it on the project
    # and build the new project.
    # @see build
    # @see update_snapshot
    # @raise The original exception when the update fails
    def build_and_publish(current_user = nil)
      update(:status => 'building')
      ActiveJob::Chain.new(
        SyncBlueprintJob.new(blueprint, :current_user => current_user),
        SyncProjectJob.new(self),
        BuildJob.new(
          self,
          :target => 'publish',
          :current_user => current_user
        )
      ).catch(SetStatusJob.new(self, 'broken')).enqueue
    rescue
      update!(:status => 'broken')
      raise
    end

    # Gets the directory path to which the project will be deployed to.
    # @return [String] deployment directory path.
    def deploy_dir
      if blueprint_config.present? && blueprint_config['deploy_dir']
        blueprint_config['deploy_dir']
      else
        'build'
      end
    end

    # Gets the URL for previewing the project.
    # @return [String] preview URL for the project.
    def preview_url
      @preview_url ||= deployer(:preview).url_for('/')
    end

    # Gets the URL to the published version of the project.
    # @return [String] publish URL for the project.
    def publish_url
      @publish_url ||= deployer(:publish).url_for('/')
    end

    # Gets the slug of the project without the theme.
    # Handles when the theme changes
    # @return [String] slyg of the project without the theme.
    def slug_sans_theme
      if theme_changed? && theme_was
        slug.sub(/^(#{theme.slug}|#{theme_was.slug})-/, '')
      else
        slug.sub(/^#{theme.slug}-/, '')
      end
    end

    # Gets the old theme if it was changed.
    # @return [Theme] Old theme if it was changed. `nil` if the theme was not changed.
    def theme_was
      return @theme_was if @theme_was && @theme_was.id == theme_id_was
      @theme_was = theme_id_was.nil? ? nil : Theme.find(theme_id_was)
    end

    # Checks if the theme was changed for the project
    # @return [Boolean] `true` if the theme was changed, `false` otherwise.
    def theme_changed?
      theme_id_changed?
    end

    # Type of the blueprint for the project.
    # @return [Boolean] the type of the blueprint. Eg: `graphic` or `app`
    def type
      if blueprint_config
        blueprint_config['type']
      elsif blueprint
        blueprint.type
      elsif blueprint_id
        Blueprint.find(blueprint_id).type
      end
    end

    def deployed?
      status != 'new' && blueprint_version.present?
    end

    def installed?
      status != 'new' && blueprint_version.present?
    end

    # Checks if the project has built
    # @return [Boolean] `true` if the project has output, `false` otherwise.
    def built?
      output.present?
    end

    # Rails reserves the column `type` for itself. Here we tell Rails to use a
    # different name.
    def self.inheritance_column
      'class'
    end

    private

    def check_for_updated_data
      self.data_updated_at = DateTime.current if data_changed?
    end

    def pub_to_redis
      msg = { :id => id,
              :model => 'project',
              :status => status }
      Autotune.send_message('change', msg) if Autotune.can_message?
    end
  end
end
