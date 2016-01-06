# This migration comes from autotune (originally 20151221172822)
class CreateGroups < ActiveRecord::Migration
  def change
    create_table :autotune_groups do |t|
      t.string :name
    end

    # Add many to many relation between groups and users through memberships
    create_table :autotune_group_memberships do |t|
      t.references :user, index: true
      t.references :group, index: true
      t.string :role

      t.timestamps null: false
    end
    add_foreign_key :autotune_group_memberships, :autotune_users, column: :user_id
    add_foreign_key :autotune_group_memberships, :autotune_groups, column: :group_id

    # Add 1:n relation between projects and groups
    add_column :autotune_projects, :group_id, :integer
    add_foreign_key :autotune_projects, :autotune_groups, column: :group_id

    # Add 1:n relation between projects and themes
    add_column :autotune_themes, :group_id, :integer
    add_foreign_key :autotune_themes, :autotune_groups, column: :group_id

    # Adding initial data - TODO (Kavya) change this later to a configuration setting
    require 'yaml'
    group_theme_map_file = File.join(Rails.root, 'config/chorus_theme_map.yml')
    if File.exist?(group_theme_map_file) then
      group_theme_map = YAML.load_file(group_theme_map_file)

      group_theme_map.each do |g|
        puts "create group #{g['name']}"
        group = Autotune::Group.find_or_create_by :name => g['name']
        theme = Autotune::Theme.find_by(:value => g['theme'])
        if !theme.nil?
          if !theme.group.nil?
            theme = theme.dup
            theme.value = "#{group.name.downcase.gsub ' ', '_'}"
          end
          theme.label = "#{group.name}"
          theme.group = group
          theme.save!
        else
          puts "Create theme #{g['theme']}"
          Autotune::Theme.find_or_create_by :label => g['name'],
           :value => g['theme'], :group => group
        end
      end

      Autotune::Project.all.each do |project|
        project.group = project.theme.group
        project.save!
      end

      Autotune::Blueprint.all.each do |blueprint|
          blueprint_themes = select_rows "SELECT theme_id from autotune_blueprints_themes
            WHERE blueprint_id = #{blueprint.id};"
          blueprint_themes.each do |t|
            bp_theme = Autotune::Theme.find_by_id(t[0])
            blueprint.groups << bp_theme.group
          end
        blueprint.save!
      end
    end

    # remove relation between blueprints and themes
    drop_table :autotune_blueprints_themes
  end
end
