class AddDetailsToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :meta, :text
    add_reference :themes, :group, index: true, foreign_key: true
  end
end
