class AddDetailsToThemes < ActiveRecord::Migration
  def change
    add_column :autotune_themes, :theme_config, :text
  end
end
