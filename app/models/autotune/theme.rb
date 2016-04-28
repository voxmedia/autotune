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

    before_validation :update_parent, :on => :create
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

    def update_parent
      return if parent.present? || group.nil?
      parent_theme = Theme.get_default_theme_for_group(group.id)
      self.parent = parent_theme unless parent_theme == self
    end

    # Merge data with parent and generic themes
    def config_data
      generic_theme_data = Rails.configuration.autotune.generic_theme
      return generic_theme_data.deep_merge(data) if parent.nil?
      inherited_data = generic_theme_data.deep_merge(parent.data)
      inherited_data.deep_merge(data)
    end

    def update_data(build_blueprints: true)
      update!(:status => 'updating')
      SyncThemeJob.perform_later(self, :build_blueprints => build_blueprints)
    rescue
      update!(:status => 'broken')
      raise
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

    # Check if this is a default theme
    def is_default?
      parent.nil?
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

    # Get default theme for group
    def self.get_default_theme_for_group(group_id)
      Theme.find_by(
        :parent_id => nil,
        :group_id => group_id)
    end

    def pub_to_redis
      msg = { :model => 'theme',
              :id => id,
              :status => status }
      Autotune.send_message('change', msg) if Autotune.can_message?
    end
  end
end
