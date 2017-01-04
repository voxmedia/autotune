class BespokeProjects < ActiveRecord::Migration
  def change
    add_column :autotune_projects, :bespoke, :boolean, :null => false, :default => false
    add_column :autotune_projects, :blueprint_repo_url, :string
  end
end
