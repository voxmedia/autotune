class CreateThemes < ActiveRecord::Migration
  def change
    create_table :autotune_themes do |t|
      t.string :value
      t.string :label
    end

    create_table :autotune_blueprints_themes, id: false do |t|
      t.integer :theme_id, index: true
      t.integer :blueprint_id, index: true
    end

    add_reference :autotune_projects, :theme, index: true
    add_foreign_key :autotune_projects, :autotune_themes, column: :theme_id

    themes = {}
    Rails.configuration.autotune.themes.each do |k, v|
      puts "create theme: #{k} => #{v}"
      themes[k.to_sym] = Autotune::Theme.create! :value => k, :label => v
    end

    Autotune::Project.all.each do |project|
      old_theme = project.attributes['theme']
      if old_theme == 'default' || old_theme == '' || old_theme.nil?
        project.theme = themes[:generic]
      else
        project.theme = themes[old_theme.to_sym]
      end
      project.save!
    end

    remove_column :autotune_projects, :theme
  end
end
