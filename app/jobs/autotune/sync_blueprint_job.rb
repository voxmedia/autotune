require 'autoshell'

module Autotune
  # setup the blueprint
  class SyncBlueprintJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    # do the deed
    def perform(blueprint, update: false, build_themes: false, current_user: nil)
      return unless blueprint.sync_from_repo(update: update) || build_themes

      if blueprint.config['preview_type'] == 'live' && blueprint.config['sample_data']
        repo = blueprint.build_shell

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
            repo.cd { |s| s.run BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json }

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
