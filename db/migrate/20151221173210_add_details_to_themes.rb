class AddDetailsToThemes < ActiveRecord::Migration
  def change
    add_column :autotune_themes, :data, :mediumtext
    add_reference :autotune_themes, :parent, index: true
    add_foreign_key :autotune_themes, :autotune_themes, column: :parent_id
  end
end
