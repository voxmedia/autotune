class CreateBlueprintTags < ActiveRecord::Migration
  def change
    create_table :autotune_blueprint_tags do |t|
      t.references :blueprint, index: true
      t.references :tag, index: true

      t.timestamps null: false
    end
    add_foreign_key :blueprint_tags, :blueprints
    add_foreign_key :blueprint_tags, :tags
  end
end
