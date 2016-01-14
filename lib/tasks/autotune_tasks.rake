namespace :autotune do
  desc 'Update all the blueprints'
  task :update_blueprints => :environment do
    puts 'Updating all blueprints'
    Autotune::Blueprint.all.each { |b| b.update_repo }
  end

  desc 'Sync all the blueprints'
  task :sync_blueprints => :environment do
    puts 'Updating all blueprints'
    Autotune::Blueprint.all.each do |b|
      Autotune::SyncBlueprintJob.perform_later b
    end
  end

  desc 'Reset all the blueprints themes'
  task :reset_blueprint_themes => :environment do
    puts 'Updating all blueprints'
    Autotune::Blueprint.all.each do |b|
      b.initialize_themes_from_config
      b.save!
    end
  end

  desc 'Rebuild previews for all projects'
  task :rebuild_previews => :environment do
    puts 'Rebuilding all previews'
    Autotune::Project.all.each { |p| p.build }
  end

  desc "Delete users that haven't created projects"
  task :clean_users => :environment do
    puts 'Deleting users'
    Autotune::User.all.each do |u|
      next if Autotune::Project.where(user: u).count > 0
      puts "#{u.name} <#{u.email}>"
      u.destroy
    end
  end

  desc 'Remove all working dir files'
  task :clean_working => :environment do
    puts 'Deleting folders'
    require 'fileutils'
    FileUtils.rm_rf(Rails.configuration.autotune.working_dir)
  end

  desc 'Remove all project files'
  task :clean_projects => :environment do
    puts 'Deleting project folders'
    require 'fileutils'
    FileUtils.rm_rf(
      File.join(Rails.configuration.autotune.working_dir, 'projects'))
  end

  desc 'List out of date projects'
  task :list_upgradable_projects => :environment do
    puts 'Projects which are out of date:'
    Autotune::Project.all.each do |proj|
      puts proj.slug if proj.blueprint.version != proj.blueprint_version
    end
  end

  desc 'Create machine user'
  task :create_superuser, [:set_email] => [:environment] do |t, args|
    u = Autotune::User.find_or_create_by({
        :name => 'autobot_machine'
      })
    u.attributes = {
      :email => args[:set_email],
      :meta => { 'roles' => [:superuser] }
    }
    u.save!
    puts u.as_json
  end

end
