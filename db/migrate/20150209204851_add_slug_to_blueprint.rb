class AddSlugToBlueprint < ActiveRecord::Migration
  def change
    add_column :blueprints, :blueprints, :string
    add_column :blueprints, :slug, :string
  end
end
