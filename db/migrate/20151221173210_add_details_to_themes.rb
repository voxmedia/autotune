class AddDetailsToThemes < ActiveRecord::Migration
  def change
    add_column :autotune_themes, :theme_config, :text
    add_column :autotune_themes, :group_id, :integer
    add_foreign_key :autotune_themes, :autotune_groups, column: :group_id
  end
end
