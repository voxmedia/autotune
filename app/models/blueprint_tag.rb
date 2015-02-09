class BlueprintTag < ActiveRecord::Base
  belongs_to :blueprint
  belongs_to :tag
end
