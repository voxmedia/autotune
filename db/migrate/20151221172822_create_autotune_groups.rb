class CreateAutotuneGroups < ActiveRecord::Migration
  def change
    create_table :autotune_groups do |t|
      t.string :title
    end

    # Add many to many relation between groups and blueprints
    create_table :autotune_blueprints_groups, :id => false do |t|
      t.references :blueprint, index: true
      t.references :group, index: true
    end
    add_foreign_key :autotune_blueprints_groups, :autotune_groups, column: :group_id
    add_foreign_key :autotune_blueprints_groups, :autotune_blueprints, column: :blueprint_id
  end
end
