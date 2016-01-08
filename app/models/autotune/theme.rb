module Autotune
  # Themes for blueprints
  class Theme < ActiveRecord::Base
    include Slugged
    include Searchable
    serialize :data, JSON

    belongs_to :group
    belongs_to :parent, class_name: "Theme"
    has_many :children, class_name: "Theme", foreign_key: "parent_id"

    validates :slug, :title, :group, :presence => true
    validates :slug,
              :uniqueness => true,
              :format => { :with => /\A[0-9a-z\-_]+\z/ }

    after_initialize :defaults
    default_scope { order('title ASC') }

    # Merge data with parent theme
    def config_data
      return data if parent.nil?
      return parent.data.merge!(data)
    end

    private
    def defaults
      self.data ||= {}
    end
  end
end
