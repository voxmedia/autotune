class CreateBlueprints < ActiveRecord::Migration
  def change
    create_table :blueprints do |t|
      t.string :title
      t.string :status
      t.string :repo_url

      t.timestamps null: false
    end
  end
end
