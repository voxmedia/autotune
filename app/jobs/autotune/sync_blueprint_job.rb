require 'work_dir'

module Autotune
  # setup the blueprint
  class SyncBlueprintJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    # do the deed
    def perform(blueprint, update: false, build_themes: false, current_user: nil)
      # Create a new repo object based on the blueprints working dir
      repo = WorkDir.repo(blueprint.working_dir,
                          Rails.configuration.autotune.setup_environment)

      if repo.exist?
        repo.branch_from_repo_url(blueprint.repo_url)
        if update
          # Update the repo
          repo.update
          blueprint.version = repo.version
        elsif blueprint.status.in?(%w(testing ready)) &&
              blueprint.version == repo.version &&
              !build_themes
          # The correct blueprint files are on disk, and the blueprint is not
          # broken. And we are not rebuilding themes. Nothing to do.
          return
        elsif !update
          # we're not updating, but the blueprint is broken, so set it up
          repo.commit_hash_for_checkout = blueprint.version
          repo.update
        end
      else
        # Clone the repo
        repo.clone(blueprint.repo_url)
        if blueprint.version.present?
          repo.commit_hash_for_checkout = blueprint.version
          repo.update
        else
          # Track the current commit version
          blueprint.version = repo.version
          repo.update
        end
      end

      # Setup the environment
      repo.setup_environment

      # Load the blueprint config file into the DB
      blueprint.config = repo.read BLUEPRINT_CONFIG_FILENAME
      if blueprint.config.nil?
        raise "Can't read '%s' in blueprint '%s'" % [
          BLUEPRINT_CONFIG_FILENAME, blueprint.slug]
      end

      # Stash the thumbnail
      if blueprint.config['thumbnail'] && repo.exist?(blueprint.config['thumbnail'])
        blueprint.deployer(:media).deploy_file(
          blueprint.working_dir,
          blueprint.config['thumbnail'])
      end

      if blueprint.config['preview_type'] == 'live' && blueprint.config['sample_data']
        repo = WorkDir.repo(blueprint.working_dir,
                            Rails.configuration.autotune.build_environment)

        # don't build a copy for each theme every time a project is updated
        if build_themes
          sample_data = repo.read(blueprint.config['sample_data'])
          sample_data.delete('base_url')
          sample_data.delete('asset_base_url')
          sample_data.delete('available_themes') unless sample_data['available_themes'].blank?
          sample_data.delete('theme_data') unless sample_data['theme_data'].blank?

          # add themes data if this blueprint support themeing
          if blueprint.themable?
            sample_data.merge!(
              'available_themes' => Theme.all.pluck(:slug),
              'theme_data' => Theme.full_theme_data
            )
          end

          # if no theme list is available, pick the first theme
          if blueprint.config['themes'].blank?
            themes = blueprint.themable? ? [Theme.first] : Theme.where(:parent => nil)
          else # get supported themes
            themes = Theme.where(:slug => blueprint.config['themes'])
          end

          # if no theme is selected at this point, use any default theme
          themes = Theme.where(:parent => nil).first if themes.empty?

          themes.each do |theme|
            slug = blueprint.themable? ? blueprint.version : [blueprint.version, theme.slug].join('-')

            # Use this as dummy build data for the moment
            build_data = sample_data.merge(
              'title' => blueprint.title,
              'slug' => slug,
              'group' => theme.group.slug,
              'theme' => theme.slug,
              'build_type' => 'preview')

            # Get the deployer object
            # probably don't want this to always be preview
            deployer = Autotune.new_deployer(
              :media, blueprint, :extra_slug => slug)

            # Run the before build deployer hook
            deployer.before_build(build_data, repo.env, current_user)

            # Run the build
            repo.working_dir do
              repo.cmd(
                BLUEPRINT_BUILD_COMMAND,
                :stdin_data => build_data.to_json)
            end

            # Upload build
            deployer.deploy(blueprint.full_deploy_dir)
          end
        end
      end

      # Blueprint is now built
      blueprint.status = 'built'
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      blueprint.status = 'broken'
      raise
    ensure
      blueprint.save!
    end
  end
end
