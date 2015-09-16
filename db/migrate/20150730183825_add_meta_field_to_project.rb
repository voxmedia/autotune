class AddMetaFieldToProject < ActiveRecord::Migration
  def change
    add_column :autotune_projects, :meta, :text
  end
end
