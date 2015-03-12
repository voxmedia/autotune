module Autotune
  # Autotune rails app
  class Engine < ::Rails::Engine
    isolate_namespace Autotune

    # Make sure we load jbuilder for views
    require 'jbuilder'

    # Figure out where we project our blueprints
    config.working_dir = File.expand_path(ENV['WORKING_DIR'] || './working', Rails.root)
    config.blueprints_dir = File.join(config.working_dir, 'blueprints')
    config.projects_dir = File.join(config.working_dir, 'projects')
    [:working_dir, :blueprints_dir, :projects_dir].each do |s|
      Dir.mkdir(config.try(s)) unless Dir.exist?(config.try(s))
    end
  end
end
