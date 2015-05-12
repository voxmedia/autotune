class AddConfigToProjects < ActiveRecord::Migration
  def change
    add_column :autotune_projects, :blueprint_config, :text
  end
end
