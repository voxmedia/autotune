module Autotune
  # Themes for blueprints
  class Theme < ActiveRecord::Base
    include Slugged
    include Searchable
    serialize :data, JSON

    has_many :projects
    belongs_to :group
    belongs_to :parent, class_name: "Theme"
    has_many :children, class_name: "Theme", foreign_key: "parent_id"

    validates :slug, :title, :group, :presence => true
    validates :slug,
              :uniqueness => true,
              :format => { :with => /\A[0-9a-z\-_]+\z/ }
    # validate that there is only one 'default' theme per group
    validates :group_id, :uniqueness => { :scope => :parent_id }, if: ":parent_id.nil?"

    after_initialize :defaults
    default_scope { order('title ASC') }

    # Merge data with parent theme
    def config_data
      return data if parent.nil?
      return parent.data.merge(data)
    end

    # Get default theme for group
    def self.get_default_theme_for_group(group_id)
      Theme.find_by(
        :parent_id => nil,
        :group_id => group_id)
    end

    private
    def defaults
      self.data ||= {}
    end
  end
end
