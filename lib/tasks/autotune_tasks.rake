require 'net/https'
require 'uri'

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

  desc 'Correct project preview type'
  task :correct_project_preview_type => :environment do
    Autotune::Project.all.each do |proj|
      if proj.blueprint_config['preview_type'] && proj.blueprint_config['preview_type'] === 'live'
        test_theme = Autotune::Theme.find(proj.theme_id)['value']
        slug_string = "#{proj.blueprint_version}-#{test_theme}/preview/"
        blueprint = Autotune::Blueprint.find(proj.blueprint_id)
        deployer = Autotune.new_deployer(
          :media, blueprint, :extra_slug => slug_string)
        uri = URI.parse(deployer.project_asset_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        if uri.scheme === 'http'
          http.use_ssl = false
        end
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        unless response.code === '200'
          puts "#{blueprint.title} - #{proj.title}"
          proj.update_snapshot
        end
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
  task :alert_users, [:level, :text, :timeout] => [:environment] do |_, args|
    timeout = args[:timeout].to_i.to_s == args[:timeout] ? args[:timeout].to_i : args[:timeout]
    Autotune.send_message('alert', :level => args[:level],
                                   :text => args[:text],
                                   :timeout => timeout)
    puts "Sent #{args[:level]} alert to everyone: #{args[:text]}"
  end

  desc 'Reset all themes'
  task :reset_themes => :environment do
    puts 'Resetting all themes'
    Autotune::Theme.all.each_with_index do |t, i|
      build_bp = i == (Autotune::Theme.count - 1)
      t.update_data(:build_blueprints => build_bp)
    end
  end
end
