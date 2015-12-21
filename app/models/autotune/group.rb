module Autotune
  class Group < ActiveRecord::Base
    has_many :themes
  end
end
