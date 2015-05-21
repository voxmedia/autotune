require 'uri'
require 'work_dir'
require 'redis'

module Autotune
  # Blueprint
  class Blueprint < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    serialize :config, JSON
    has_many :blueprint_tags, :dependent => :destroy
    has_many :tags, :through => :blueprint_tags

    validates :title, :repo_url, :presence => true
    validates :status, :inclusion => { :in => Autotune::BLUEPRINT_STATUSES }
    after_initialize :defaults
    after_save :pub_to_redis

    search_fields :title

    default_scope { order('updated_at DESC') }

    def thumb_url
      if config['thumbnail'] && !config['thumbnail'].empty?
        File.join(
          Rails.configuration.autotune.media[:base_url],
          slug, config['thumbnail']).to_s
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
      update(:status => 'updating')
      SyncBlueprintJob.perform_later self
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

    def defaults
      self.status ||= 'new'
      self.type ||= 'app'
      self.config ||= {}
    end

    def pub_to_redis
      return if Autotune.redis.nil?
      msg = { id: id,
              status: status }
      Autotune.redis.publish 'blueprint', msg.to_json
    end
  end
end
