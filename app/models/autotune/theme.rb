module Autotune
  # Themes for blueprints
  class Theme < ActiveRecord::Base
    serialize :meta, JSON
    has_and_belongs_to_many :blueprints
    validates :value, :label, :presence => true
    validates :value,
              :uniqueness => true,
              :format => { :with => /\A[0-9a-z\-_]+\z/ }

    after_initialize do
      social_dict = {
        "sbnation" => 8,
        "theverge" => 5,
        "polygon" => 7,
        "racked" => 6,
        "eater" => 5,
        "vox" => 9,
        "custom" => 0,
        "generic" => 0
      }
      self.meta = { "social_chars" => social_dict[self.value] }
    end
  end
end
