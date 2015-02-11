class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email, :index => true
      t.string :name
      t.text :meta

      t.timestamps null: false
    end
  end
end
