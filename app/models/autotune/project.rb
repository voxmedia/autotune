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
    # Queues jobs to sync latest version of blueprint, update it on the project
    # and build the new project.
    # It publishes updates on projects already published.
    # @raise The original exception when the update fails
    # @see build_and_publish
    # @see update_snapshot
    # rubocop:disable Metrics/ParameterLists
    def build(current_user, update: false, publish: false,
              repeat_until: nil, wait_until: nil,
              convert_to_blueprint: nil, convert_to_bespoke: nil)
      # First check to see if there already is a lock on this job
      target = publishable? && !publish ? 'preview' : 'publish'
      self.status = 'building'

      # If this is a blueprint-based project and an update is requested, update
      # the version and config data from the blueprint
      if update && !bespoke? && blueprint_version != blueprint.version
        self.blueprint_version = blueprint.version
        self.blueprint_config = blueprint.config
      end

      dep = deployer(target, :user => current_user)
      dep.prep_target
      dep.after_prep_target

      job = ProjectJob.new(
        self,
        :update => update,
        :target => target,
        :current_user => current_user,
        :convert_to_blueprint => convert_to_blueprint,
        :convert_to_bespoke => convert_to_bespoke
      )
      raise 'Build cancelled, another build is already queued or running' if job.unique_lock?

      save!

      repeat_build!(Time.zone.at(repeat_until.to_i)) if repeat_until.present?

      if wait_until
        job.enqueue(:wait_until => wait_until)
      else
        job.enqueue
      end
    rescue StandardError
      update!(:status => 'broken')
      raise
    end
    # rubocop:enable Metrics/ParameterLists

    # Builds and publishes the project.
    # Updates blueprint version and builds the project.
    # Queues jobs to sync latest verison of blueprint, update it on the project
    # and build the new project.
    # @see build
    # @raise The original exception when the update fails
    def build_and_publish(current_user)
      build(current_user, :publish => true)
    end

    # Updates blueprint version and builds the project.
    # Queues jobs to sync latest verison of blueprint, update it on the project
    # and build the new project.
    # It publishes updates on projects already published.
    # @raise The original exception when the update fails
    # @see build
    def update_snapshot(current_user)
      build(current_user, :update => true)
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
      return @theme_was if defined?(@theme_was) && @theme_was && @theme_was.id == theme_id_was
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

    def repeat_build_key
      "repeat_build:#{to_gid_param}"
    end

    def repeat_build!(until_time)
      now = Time.current
      if until_time > now
        Rails.cache.write(repeat_build_key, until_time.to_i,
                          :expires_in => until_time.to_i - now.to_i)
      else
        raise 'Invalid time to repeat until'
      end
    end

    def cancel_repeat_build!
      Rails.cache.delete(repeat_build_key)
    end

    def repeat_build?
      Rails.cache.read(repeat_build_key).to_i >= Time.current.to_i
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
      %w[data title slug theme_id].each do |attr|
        begin
          # Apparently attribute_changed? does not check if the attribute actually changed
          if changes[attr].present? && changes[attr].first != changes[attr].last
            self.data_updated_at = now
            break
          end
        rescue Encoding::UndefinedConversionError => exc
          raise "#{exc.message} in field #{attr}"
        end
      end

      # update published_at field if the flag has been set
      if update_published_at
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
