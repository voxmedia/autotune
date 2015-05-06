class AddUserToProjects < ActiveRecord::Migration
  def change
    add_reference :autotune_projects, :user, index: true, foreign_key: true
    add_foreign_key :autotune_projects, :autotune_user, column: :user_id
  end
end
