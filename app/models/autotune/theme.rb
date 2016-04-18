require 'redis'

module Autotune
  # Themes for blueprints
  class Theme < ActiveRecord::Base
    include Slugged
    include Searchable
    serialize :data, JSON

    has_many :projects
    belongs_to :group
    belongs_to :parent, :class_name => 'Theme'
    has_many :children, :class_name => 'Theme', :foreign_key => 'parent_id'

    validates :slug, :title, :group, :presence => true
    validates :title,
              :uniqueness => true
    validates :slug,
              :uniqueness => true,
              :format => { :with => /\A[0-9a-z\-_]+\z/ }
    # validate that there is only one 'default' theme per group
    validates :group_id, :uniqueness => { :scope => :parent_id }, :if => ':parent_id.nil?'
    validates :status, :inclusion => { :in => Autotune::THEME_STATUSES }

    after_initialize :defaults
    default_scope { order('title ASC') }

    after_save :pub_to_redis

    # Merge data with parent theme
    def config_data
      return data if parent.nil?
      parent.data.deep_merge(data)
    end

    def update_data(build_blueprints: true)
      update!(:status => 'updating')
      SyncThemeJob.perform_later(self)
      Blueprint.rebuild_themes if build_blueprints
    rescue
      update!(:status => 'broken')
      raise
    end

    # Get default theme for group
    def self.get_default_theme_for_group(group_id)
      Theme.find_by(
        :parent_id => nil,
        :group_id => group_id)
    end

    def self.add_default_theme_for_group(group)
      default_theme = Theme.get_default_theme_for_group(group.id)
      return default_theme unless default_theme.nil?
      default_theme = Theme.create(
        :title => group.name,
        :group_id => group.id)
      default_theme.save!
      default_theme.update_data
    end

    # return group name
    def group_name
      group.name
    end

    # Return twitter handle
    def twitter_handle
      return nil if config_data['social'].blank?
      config_data['social']['twitter_handle']
    end

    # get data for all themes
    def self.full_theme_data
      Hash[Theme.all.map { |theme| [theme.slug, theme.config_data] }]
    end

    private

    def defaults
      self.data ||= {}
      self.status ||= 'new'
    end

    def pub_to_redis
      return if Autotune.redis.nil?
      msg = { :id => id,
              :status => status }
      Autotune.redis.publish 'theme', msg.to_json
    end
  end
end
