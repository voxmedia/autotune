module Autotune
  class Group < ActiveRecord::Base
    has_many :themes
    has_and_belongs_to_many :blueprints

    # TODO add validations
  end
end
