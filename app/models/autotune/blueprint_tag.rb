module Autotune
  # Blueprint/tag many:many relationship
  class BlueprintTag < ActiveRecord::Base
    belongs_to :blueprint
    belongs_to :tag
  end
end
