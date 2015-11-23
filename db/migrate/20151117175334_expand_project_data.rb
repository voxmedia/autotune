class ExpandProjectData < ActiveRecord::Migration
  def change
    change_column :autotune_projects, :data, :text, :limit => 128.kilobytes
  end
end
