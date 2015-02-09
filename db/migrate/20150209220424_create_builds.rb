class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.string :title
      t.string :slug
      t.text :data
      t.string :status
      t.text :output
      t.references :blueprint, index: true

      t.timestamps null: false
    end
    add_foreign_key :builds, :blueprints
  end
end
