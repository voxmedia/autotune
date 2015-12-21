module Autotune
  # Themes for blueprints
  class Theme < ActiveRecord::Base
    belongs_to :group
    validates :value, :label, :presence => true
    validates :value,
              :uniqueness => true,
              :format => { :with => /\A[0-9a-z\-_]+\z/ }
  end
end
