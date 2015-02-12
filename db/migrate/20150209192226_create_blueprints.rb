class CreateBlueprints < ActiveRecord::Migration
  def change
    create_table :blueprints do |t|
      t.string :slug, :index => true
      t.string :title
      t.string :status
      t.string :repo_url
      t.text :config

      t.timestamps null: false
    end
  end
end
