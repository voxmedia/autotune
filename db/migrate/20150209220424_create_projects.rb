# create projects table
class CreateProjects < ActiveRecord::Migration
  def change
    create_table :autotune_projects do |t|
      t.string :slug, :index => true
      t.string :theme, :index => true
      t.string :status, :index => true
      t.string :title
      t.string :blueprint_version
      t.text :data
      t.text :output
      t.references :blueprint, :index => true

      t.timestamps :null => false
    end
    add_foreign_key :autotune_projects, :autotune_blueprints, column: :blueprint_id
  end
end
