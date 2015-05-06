class AddUserToProjects < ActiveRecord::Migration
  def change
    add_reference :autotune_projects, :user, index: true
    add_foreign_key :autotune_projects, :autotune_users, column: :user_id
  end
end
