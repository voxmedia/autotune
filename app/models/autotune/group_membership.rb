module Autotune
  class GroupMembership < ActiveRecord::Base
    belongs_to :user
    belongs_to :group
  end
end
