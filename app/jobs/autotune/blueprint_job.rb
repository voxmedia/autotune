require 'autoshell'

module Autotune
  # setup the blueprint
  class BlueprintJob < ActiveJob::Base
    queue_as :default

    # do the deed
    def perform(blueprint, update: false, build_themes: false, current_user: nil)
      return retry_job :wait => 10 unless blueprint.file_lock!

      blueprint.update!(:status => 'updating')

      if update || blueprint.needs_sync?
        blueprint.sync_from_remote(:update => update, :current_user => current_user)
      end

      if blueprint.config['preview_type'] == 'live' && blueprint.config['sample_data']
        repo = blueprint.build_shell

        # don't build a copy for each theme every time a project is updated
        if build_themes
          # TODO: Here we could make a temp copy of the working dir and release
          # the file lock while we build every theme.

          sample_data = repo.read(blueprint.config['sample_data'])
          sample_data.delete('base_url')
          sample_data.delete('asset_base_url')
          sample_data.delete('available_themes') if sample_data['available_themes'].present?
          sample_data.delete('theme_data') if sample_data['theme_data'].present?

          # add themes data if this blueprint support themeing
          if blueprint.themable?
            sample_data['available_themes'] = Theme.all.pluck(:slug)
            sample_data['theme_data'] = Theme.full_theme_data
          end

          # if no theme list is available, pick the first theme
          themes =
            if blueprint.config['themes'].blank?
              blueprint.themable? ? [Theme.first] : Theme.where(:parent => nil)
            else # get supported themes
              Theme.where(:slug => blueprint.config['themes'])
            end

          # if no theme is selected at this point, use any default theme
          themes = Theme.where(:parent => nil).first if themes.blank?

          return if themes.blank?

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
            deployer = blueprint.deployer(:media, :user => current_user, :extra_slug => slug)

            # Run the before build deployer hook
            deployer.before_build(build_data, repo.env)
            deployer.after_before_build(build_data, repo.env)

            # Run the build
            repo.cd { |s| s.run BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json }

            # Upload build
            deployer.deploy(blueprint.full_deploy_dir)
          end
        end
      end

      # Blueprint is now built
      blueprint.status = 'built'

      # Always make sure to release the file lock and save the blueprint
      blueprint.file_unlock!
      blueprint.save!
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      blueprint.status = 'broken'

      # Always make sure to release the file lock and save the blueprint
      blueprint.file_unlock!
      blueprint.save!

      raise
    end
  end
end
