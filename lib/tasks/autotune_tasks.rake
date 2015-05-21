namespace :autotune do
  desc 'Update all the blueprints'
  task :update_blueprints => :environment do
    puts 'Updating all blueprints'
    Autotune::Blueprint.all.each { |b| b.update_repo }
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
end
