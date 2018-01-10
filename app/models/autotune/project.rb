require 'redis'

module Autotune
  # Model for Autotune projects.
  # A project is blueprint with data.
  class Project < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    include Deployable
    include Repo

    serialize :data, JSON
    serialize :meta, JSON
    serialize :blueprint_config, JSON
    belongs_to :blueprint
    belongs_to :user
    belongs_to :theme
    belongs_to :group

    # Alias these so some of the concerns work
    alias_attribute :config, :blueprint_config
    alias_attribute :version, :blueprint_version
    alias_attribute :repo_url, :blueprint_repo_url

    validates_length_of :output, :maximum => 64.kilobytes - 1
    validates :title, :user, :group, :theme, :presence => true
    validates :blueprint, :presence => true, :unless => :bespoke?
    validates :blueprint_repo_url, :presence => true, :if => :bespoke?
    validates :status,
              :inclusion => { :in => Autotune::STATUSES }

    default_scope { order('updated_at DESC') }

    search_fields :title

    before_save :update_dates

    after_save :pub_to_redis

    attr_accessor :update_published_at

    after_initialize do
      self.status ||= 'new'
      self.meta ||= {}
      self.data ||= {}
      self.blueprint_config ||= {}
      self.update_published_at = false
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

      # Make sure we stash version and config if there is none present
      if blueprint.present? && blueprint_version.blank?
        self.blueprint_version = blueprint.version
        self.blueprint_config = blueprint.config
        self.blueprint_repo_url = blueprint.repo_url
      end
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
    def update_snapshot(current_user)
      self.status = 'building'
      unless bespoke? || blueprint_version == blueprint.version
        self.blueprint_version = blueprint.version
        self.blueprint_config = blueprint.config
      end

      deployer(publishable? ? 'preview' : 'publish', :user => current_user).prep_target

      save!

      chain = ActiveJob::Chain.new
      unless bespoke?
        chain.then(SyncBlueprintJob.new(blueprint, :current_user => current_user))
      end

      chain
        .then(SyncProjectJob.new(self, :update => true, :current_user => current_user))
        .then(BuildJob.new(self,
                           :target => publishable? ? 'preview' : 'publish',
                           :current_user => current_user))
        .catch(SetStatusJob.new(self, 'broken'))
        .enqueue
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
    def build(current_user)
      self.status = 'building'

      deployer(publishable? ? 'preview' : 'publish', :user => current_user).prep_target

      save!

      chain = ActiveJob::Chain.new
      unless bespoke?
        chain.then(SyncBlueprintJob.new(blueprint, :current_user => current_user))
      end

      chain
        .then(SyncProjectJob.new(self, :current_user => current_user))
        .then(BuildJob.new(self,
                           :target => publishable? ? 'preview' : 'publish',
                           :current_user => current_user))
        .catch(SetStatusJob.new(self, 'broken'))
        .enqueue
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
    def build_and_publish(current_user)
      self.status = 'building'

      deployer('publish', :user => current_user).prep_target

      save!

      chain = ActiveJob::Chain.new
      unless bespoke?
        chain.then(SyncBlueprintJob.new(blueprint, :current_user => current_user))
      end

      chain
        .then(SyncProjectJob.new(self, :current_user => current_user))
        .then(BuildJob.new(self,
                           :target => 'publish',
                           :current_user => current_user))
        .catch(SetStatusJob.new(self, 'broken'))
        .enqueue
    rescue
      update!(:status => 'broken')
      raise
    end

    # Gets the URL for previewing the project.
    # @return [String] preview URL for the project.
    def preview_url(current_user)
      @preview_url ||= deployer(:preview, :user => current_user).url_for('/')
    end

    # Gets the URL to the published version of the project.
    # @return [String] publish URL for the project.
    def publish_url(current_user)
      @publish_url ||= deployer(:publish, :user => current_user).url_for('/')
    end

    # Gets the slug of the project without the theme.
    # Handles when the theme changes
    # @return [String] slug of the project without the theme.
    def slug_sans_theme
      return if slug.nil?
      if theme_changed? && theme_was.present?
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
      blueprint_config['type'] if blueprint_config.present?
    end

    def installed?
      deployed?
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

    def update_dates
      now = DateTime.current

      # check for updated data
      %w(data title slug theme_id data).each do |attr|
        # Apparently attribute_changed? does not check if the attribute actually changed
        if changes[attr].present? && changes[attr].first != changes[attr].last
          self.data_updated_at = now
          break
        end
      end

      # update published_at field if the flag has been set
      if self.update_published_at
        self.published_at = now
        self.update_published_at = false
      end

      true # make sure we return true to continue the save
    end

    def pub_to_redis
      msg = { :id => id,
              :model => 'project',
              :status => status }
      Autotune.send_message('change', msg) if Autotune.can_message?
    end
  end
end
