# create the blueprint table
class CreateBlueprints < ActiveRecord::Migration
  def change
    create_table :autotune_blueprints do |t|
      t.string :slug, :index => true
      t.string :type, :index => true
      t.string :status, :index => true
      t.string :title
      t.string :repo_url
      t.string :version
      t.text :config

      t.timestamps null: false
    end
  end
end
