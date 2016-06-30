class AddModeToBlueprint < ActiveRecord::Migration
  def change
    add_column :autotune_blueprints, :mode, :string, :index => true

    Autotune::Blueprint.where(:status => 'testing')
      .update_all(:status => 'built', :mode => 'testing')
    Autotune::Blueprint.where(:status => 'ready')
      .update_all(:status => 'built', :mode => 'ready')
  end
end
