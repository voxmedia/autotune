require 'uri'
require 'work_dir'
require 'redis'

module Autotune
  # Blueprint
  class Blueprint < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    include Deployable
    serialize :config, JSON
    has_many :blueprint_tags, :dependent => :destroy
    has_many :tags, :through => :blueprint_tags
    has_many :projects
    has_and_belongs_to_many :themes

    validates :title, :repo_url, :presence => true
    validates :repo_url, :uniqueness => { :case_sensitive => false }
    validates :status, :inclusion => { :in => Autotune::BLUEPRINT_STATUSES }
    after_save :pub_to_redis

    default_scope { order('updated_at DESC') }

    after_initialize do
      self.status ||= 'new'
      self.type   ||= 'app'
      self.preview_type ||= 'static'
      self.config ||= {}
    end

    before_validation do
      # Get the type from the config
      self.type = config['type'].downcase if config && config['type']

      update_tags_from_config
      update_themes_from_config
    end

    def thumb_url
      if config['thumbnail'] && !config['thumbnail'].empty?
        deployer(:media).url_for(config['thumbnail'])
      else
        ActionController::Base.helpers.asset_path('autotune/at_placeholder.png')
      end
    end

    def installed?
      updating? || ready? || testing?
    end

    def updating?
      status == 'updating'
    end

    def ready?
      status == 'ready'
    end

    def testing?
      status == 'testing'
    end

    def update_repo
      final_status = ready? ? 'ready' : 'testing'
      update!(:status => 'updating')
      SyncBlueprintJob.perform_later(
        self, :status => final_status, :update => true)
    rescue
      update!(:status => 'broken')
      raise
    end

    # Rails reserves the column `type` for itself. Here we tell Rails to use a
    # different name.
    def self.inheritance_column
      'class'
    end

    private

    def update_themes_from_config
      # Associate themes
      if config.present? && config['themes'].present?
        tmp_themes = []
        config['themes'].each do |t|
          next unless Autotune.config.themes.include? t.to_sym
          tmp_themes << Theme.find_or_create_by(
            :value => t, :label => Autotune.config.themes[t.to_sym])
        end
        self.themes = tmp_themes
      else
        self.themes = Autotune.config.themes.map do |value, label|
          Theme.find_or_create_by(:value => value, :label => label)
        end
      end
    end

    def update_tags_from_config
      self.tags = config['tags'].map do |t|
        Tag.find_or_create_by(:title => t.humanize)
      end if config.present? && config['tags'].present?
    end

    def pub_to_redis
      return if Autotune.redis.nil?
      msg = { :id => id,
              :status => status }
      Autotune.redis.publish 'blueprint', msg.to_json
    end
  end
end
