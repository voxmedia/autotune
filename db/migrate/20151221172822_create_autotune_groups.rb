class CreateAutotuneGroups < ActiveRecord::Migration
  def change
    create_table :autotune_groups do |t|
      t.string :title
    end
  end
end
