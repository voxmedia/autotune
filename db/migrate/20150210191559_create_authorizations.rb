class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.references :user, index: true
      t.string :provider, index: true
      t.string :uid, index: true
      t.text :info
      t.text :credentials
      t.text :extra

      t.timestamps null: false
    end
    add_foreign_key :authorizations, :users
  end
end
