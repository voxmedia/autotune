class AddDetailsToThemes < ActiveRecord::Migration
  def change
    add_column :autotune_themes, :data, :mediumtext
  end
end
