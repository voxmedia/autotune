class AddModeToBlueprint < ActiveRecord::Migration
  def change
    add_column :autotune_blueprints, :mode, :string, :index => true
  end
end
