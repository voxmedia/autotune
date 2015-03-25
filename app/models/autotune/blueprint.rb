require 'uri'
require 'work_dir'

module Autotune
  # Blueprint
  class Blueprint < ActiveRecord::Base
    include Slugged
    include Searchable
    serialize :config, Hash
    has_many :blueprint_tags
    has_many :tags, :through => :blueprint_tags

    validates :title, :repo_url, :presence => true
    validates :status, :inclusion => { :in => Autotune::BLUEPRINT_STATUSES }
    validates :repo_url,
              :format => { :with => Autotune::REPO_URL_RE },
              :uniqueness => true
    after_initialize :defaults

    search_fields :title

    def working_dir
      File.join(Rails.configuration.autotune.blueprints_dir, slug)
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
