module Autotune
  class Group < ActiveRecord::Base
    has_many :themes
    has_and_belongs_to_many :blueprints
    has_many :group_memberships
    has_many :users, through: :group_memberships

    # TODO (Kavya) add validations
  end
end
