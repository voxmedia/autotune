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

  desc 'Correct project type'
  task :correct_project_type, [:blueprint_slug] => [:environment] do |_, args|
    blueprint = Autotune::Blueprint.find_by_slug(args[:blueprint_slug])
    Autotune::Project.where(:blueprint_id => blueprint.id).each do |proj|
      if proj.type != blueprint.type
        original_type = proj.type
        proj.blueprint_config['type'] = blueprint.type
        proj.save!
        puts "'#{proj.title}' type changed from '#{original_type}' to '#{proj.type}'"
      end
    end
  end

  desc 'Create machine user'
  task :create_superuser, [:email] => [:environment] do |_, args|
    u = Autotune::User
        .create_with(
          :name => 'autobot_machine', :meta => { 'roles' => [:superuser] })
        .find_or_create_by!(:email => args[:email])
    puts "Superuser with name '#{u.name}' and email '#{u.email}':"
    puts "User ID: #{u.id}"
    puts "API key: #{u.api_key}"
  end

  desc 'Get API key'
  task :get_api_key, [:email] => [:environment] do |_, args|
    u = Autotune::User.find_by_email(args[:email])

    if u.blank?
      puts "No user found with email address #{args[:email]}"
    else
      puts "Account with name '#{u.name}' and email '#{u.email}':"
      puts "User ID: #{u.id}"
      puts "API key: #{u.api_key}"
    end
  end

  desc 'Reset API key'
  task :reset_api_key, [:email] => [:environment] do |_, args|
    u = Autotune::User.find_by_email(args[:email])

    if u.blank?
      puts "No user found with email '#{args[:email]}'"
    else
      u.update!(:api_key => Autotune::User.generate_api_key)
      puts "Reset API key for account with name '#{u.name}' and email '#{u.email}':"
      puts "User ID: #{u.id}"
      puts "API key: #{u.api_key}"
    end
  end

  desc 'Send a message to users'
  task :alert_users, [:level, :text] => [:environment] do |_, args|
    Autotune.send_message('alert', :level => args[:level], :text => args[:text])
    puts "Sent #{args[:level]} alert to everyone: #{args[:text]}"
  end
end
