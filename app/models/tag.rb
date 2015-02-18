# Tags are applied to blueprints, and used for organizing blueprints
class Tag < ActiveRecord::Base
  include Slugged
  validates :title, :slug, :presence => true
  has_many :blueprint_tags
  has_many :blueprints, :through => :blueprint_tags
end
