# This migration comes from autotune (originally 20151221172822)
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

    add_column :autotune_projects, :group_id, :integer
    add_foreign_key :autotune_projects, :autotune_groups, column: :group_id

    # update themes
    add_column :autotune_themes, :group_id, :integer
    add_foreign_key :autotune_themes, :autotune_groups, column: :group_id

    # Adding initial data - TODO change this later to a configuration setting
    require 'yaml'
    group_theme_map_file = File.join(Rails.root, 'config/chorus_theme_map.yml')
    if File.exist?(group_theme_map_file) then
      group_theme_map = YAML.load_file(group_theme_map_file)

      group_theme_map.each do |g|
        puts "create group #{g['name']}"
        group = Autotune::Group.create! :title => g['name']
        puts "update theme #{g['theme']}"
        theme = Autotune::Theme.find_by(:value => g['theme'])
        theme = theme.new if theme.nil?
        if !theme.group.nil?
          theme = theme.dup
          theme.label = "#{group.name} #{theme.label}"
          theme.value = "#{group.name}_#{theme.value}"
        end
        theme.group = group
        theme.save!
      end

      Autotune::Project.all.each do |project|
        project.group = project.theme.group
        project.save!
      end

      Autotune::Blueprint.all.each do |blueprint|
        blueprint.themes.all do |t|
          blueprint.groups << t.group
        end
        blueprint.save!
      end
    end

    drop_table :autotune_blueprints_themes
  end
end
