require 'uri'
require 'work_dir'

module Autotune
  # Blueprint
  class Blueprint < ActiveRecord::Base
    include Slugged
    include Searchable
    include WorkingDir
    serialize :config, Hash
    has_many :blueprint_tags
    has_many :tags, :through => :blueprint_tags

    validates :title, :repo_url, :presence => true
    validates :status, :inclusion => { :in => Autotune::BLUEPRINT_STATUSES }
    after_initialize :defaults

    search_fields :title

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
      %w(updating testing ready).include? status
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
    end
  end
end
