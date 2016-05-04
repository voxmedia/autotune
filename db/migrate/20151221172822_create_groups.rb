# This migration comes from autotune (originally 20151221172822)
# This migration comes from autotune (originally 20151221172822)
class CreateGroups < ActiveRecord::Migration
  def change
    create_table :autotune_groups do |t|
      t.string :name, index: true
      t.string :slug, index: true
      t.integer :external_id
    end

    # Add many to many relation between groups and users through memberships
    create_table :autotune_group_memberships do |t|
      t.references :user, index: true
      t.references :group, index: true
      t.string :role
    end
    add_foreign_key :autotune_group_memberships, :autotune_users, column: :user_id
    add_foreign_key :autotune_group_memberships, :autotune_groups, column: :group_id

    # Add 1:n relation between projects and groups
    add_column :autotune_projects, :group_id, :integer
    add_foreign_key :autotune_projects, :autotune_groups, column: :group_id

    # Add 1:n relation between projects and themes
    add_column :autotune_themes, :group_id, :integer
    add_column :autotune_themes, :status, :string
    add_index :autotune_themes, :status

    # Add data and theme inheritance model
    rename_column :autotune_themes, :value, :slug
    rename_column :autotune_themes, :label, :title
    add_column :autotune_themes, :data, :mediumtext
    add_reference :autotune_themes, :parent, index: true


    add_foreign_key :autotune_themes, :autotune_groups, column: :group_id
    add_foreign_key :autotune_themes, :autotune_themes, column: :parent_id

    # Adding initial data
    require 'yaml'
    group_theme_map_file = File.join(Rails.root, 'config/theme_map.yml')
    if File.exist?(group_theme_map_file) then
      group_theme_map = YAML.load_file(group_theme_map_file)

      group_theme_map.each do |g|
        next if g['theme'].nil?
        puts "Mapping group #{g['name']} and #{g['theme']}..."
        theme = Autotune::Theme.find_by(:slug => g['theme'])
        if theme.nil?
          theme = Autotune::Theme.find_or_create_by :title => g['name'], :slug => g['theme']
        end

        if theme.group.nil?
          puts "Creating group #{g['name']}"
          group = Autotune::Group.find_or_create_by :name => g['name']
          theme.group = group
          theme.save!

          # update data but delay blueprint rebuilding
          theme.update_data(build_blueprints: false )
        end
      end

      # delete all unused themes
      unusedThemes = Autotune::Theme.find_by :group => nil
      unusedThemes.delete unless unusedThemes.nil?

      # now that all the themes are created, rebuild all the blueprints
      Autotune::Blueprint.rebuild_themed_blueprints

      Autotune::Project.all.each do |project|
        project.group = project.theme.group
        project.save!
      end
    end

    # remove relation between blueprints and themes
    drop_table :autotune_blueprints_themes
  end
end
