class Build < ActiveRecord::Base
  include Slugged
  belongs_to :blueprint

  validates :title, :blueprint, :presence => true
end
