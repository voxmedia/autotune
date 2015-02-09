class Tag < ActiveRecord::Base
  include Slugged
  validates :title, :presence => true
  has_many :blueprint_tags
  has_many :blueprints, :through => :blueprint_tags
end
