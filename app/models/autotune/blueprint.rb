require 'uri'
require 'work_dir'
require 'redis'

# Main autotune module
module Autotune
  # Model for Autotune blueprints.
  class Blueprint < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    include Deployable
    serialize :config, JSON
    has_many :blueprint_tags, :dependent => :destroy
    has_many :tags, :through => :blueprint_tags
    has_many :projects

    validates :title, :repo_url, :presence => true
    validates :repo_url, :uniqueness => { :case_sensitive => false }
    validates :status, :inclusion => { :in => Autotune::BLUEPRINT_STATUSES }
    validates :mode, :inclusion => { :in => Autotune::BLUEPRINT_MODES }
    after_save :pub_to_redis

    default_scope { order('updated_at DESC') }

    search_fields :title

    after_initialize do
      self.status ||= 'new'
      self.type ||= 'app'
      self.mode ||= 'testing'
      self.config ||= {}
    end

    before_validation do
      # Get the type from the config
      self.type = config['type'].downcase if config && config['type']
    end

    # Gets the thumbnail image url for the blueprint
    # @return [String] thumbnail url.
    def thumb_url
      if config['thumbnail'] && !config['thumbnail'].empty?
        deployer(:media).url_for(config['thumbnail'])
      else
        ActionController::Base.helpers.asset_path('autotune/at_placeholder.png')
      end
    end

    # Checks if the blueprint has finished installing
    # @return [Boolean] `true` if the blueprint is installed, `false` otherwise.
    def installed?
      status != 'new' && version.present?
    end

    # Checks if the blueprint is currently updating
    # @return [Boolean] `true` if the blueprint is updating, `false` otherwise.
    def updating?
      status == 'updating'
    end

    # Checks if the blueprint is ready for use
    # @return [Boolean] `true` if the blueprint is ready, `false` otherwise.
    def ready?
      mode == 'ready'
    end

    # Checks if the blueprint is in testing state
    # @return [Boolean] `true` if the blueprint status is `testing`, `false` otherwise.
    def testing?
      mode == 'testing'
    end

    # Checks if the blueprint is installed
    # @return [Boolean] `true` if the blueprint is installed, `false` otherwise.
    def deployed?
      status != 'new' && version.present?
    end

    # Check if the blueprint is ready for themeing
    # @return [Boolean] `true` if the blueprint is not tied to specific themes, `false` otherwise
    def themable?
      config['theme_type'].present? && config['theme_type'] == 'dynamic'
    end

    # Queues a job to update the blueprint repo
    def update_repo
      update!(:status => 'updating')
      SyncBlueprintJob.perform_later(
        self, :update => true, :build_themes => true)
    rescue
      update!(:status => 'broken')
      raise
    end

    # Rebuild all themeable blueprints. Used when themes are updated
    def self.rebuild_themed_blueprints
      jobs = Blueprint.all
             .select(&:themable?)
             .collect { |bp| SyncBlueprintJob.new(bp, :build_themes => true) }

      ActiveJob::Chain.new(*jobs).enqueue
    end

    # Rails reserves the column `type` for itself. Here we tell Rails to use a
    # different name.
    def self.inheritance_column
      'class'
    end

    private

    def deploy_dir
      if config.present? && config['deploy_dir']
        config['deploy_dir']
      else
        'build'
      end
    end

    # Publishes status changes to redis
    def pub_to_redis
      msg = { :model => 'blueprint',
              :id => id,
              :status => status }
      Autotune.send_message('change', msg) if Autotune.can_message?
    end
  end
end
