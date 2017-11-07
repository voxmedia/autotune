require 'uri'
require 'autotune/google_docs'
require 'date'

module Autotune
  # Autotune blueprint base deployer
  class Deployer
    attr_accessor :base_url, :connect, :project, :extra_slug
    attr_writer :logger, :user

    # Create a new deployer
    def initialize(kwargs)
      kwargs.each do |k, v|
        send "#{k}=".to_sym, v
      end
      raise 'missing deployable' if kwargs[:project].nil?
    end

    # Deploy an entire directory
    def deploy(_source)
      raise NotImplementedError
    end

    # Deploy one file
    def deploy_file(_source, _path)
      raise NotImplementedError
    end

    # Hook for adjusting data and files before build
    def before_build(build_data, _env)
      if build_data['google_doc_url'].present? && user.present?
        current_auth = user.authorizations.find_by!(:provider => 'google_oauth2')
        if current_auth.present?
          google_client = GoogleDocs.new(
            :refresh_token => current_auth.credentials['refresh_token'],
            :access_token => current_auth.credentials['token'],
            :expires_at => current_auth.credentials['expires_at'])

          current_auth.credentials['refresh_token'] = google_client.auth.refresh_token
          current_auth.credentials['token'] = google_client.auth.access_token
          current_auth.credentials['expires_at'] = google_client.auth.expires_at
          current_auth.save!

          doc_key = GoogleDocs.key_from_url(build_data['google_doc_url'])
          if doc_key.present?
            resp = google_client.find(doc_key)
            cache_key = "googledoc#{doc_key}"

            if Rails.cache.exist?(cache_key)
              cache_value = Rails.cache.read(cache_key)
              needs_update = cache_value['version'] && resp['version'] != cache_value['version']
            else
              needs_update = true
            end

            if needs_update
              google_client.share_with_domain(
                doc_key, Autotune.configuration.google_auth_domain)
              ss_data = google_client.get_doc_contents(build_data['google_doc_url'])
              build_data['google_doc_data'] = ss_data
              Rails.cache.write(cache_key, 'ss_data' => ss_data, 'version' => resp['version'])
            else
              build_data['google_doc_data'] = Rails.cache.read(cache_key)['ss_data']
            end
          end
        end
      end

      build_data['title'] = project.title unless build_data['title'].present?
      build_data['slug'] = project.slug unless build_data['slug'].present?
      build_data['available_themes'] = Theme.all.pluck(:slug) unless build_data['available_themes'].present?
      build_data['theme_data'] = Theme.full_theme_data unless build_data['theme_data'].present?
      build_data['group'] = project.group.slug if project.respond_to?(:group) && project.group
      build_data['theme'] = project.theme.slug if project.respond_to?(:theme) && project.theme

      build_data['base_url'] = project_url
      build_data['asset_base_url'] = project_asset_url
    rescue GoogleDocs::GoogleDriveError => exc
      logger.error(exc)
      project.meta['error_message'] = "Error retriving google doc data: #{exc.message}"

      raise
    rescue GoogleDocs::Unauthorized => exc
      logger.error(exc)
      project.meta['error_message'] = "Unable to retrieve Google Doc because user session expired."

      raise
    rescue GoogleDocs::Forbidden => exc
      logger.error(exc)
      project.meta['error_message'] = "Unable to retrieve Google Doc because user does not have access."

      raise
    end

    # Hook to do stuff after a project is deleted
    def delete!(*)
      raise NotImplementedError
    end

    # Hook to do stuff after a project is moved (slug changed)
    def move!
      raise NotImplementedError
    end

    # Get the url to a file
    def url_for(path)
      return project_url if path == '/' || path.blank?

      path = path[1..-1] if path[0] == '/'

      if asset?(path)
        [project_asset_url, path].join('/')
      else
        [project_url, path].join('/')
      end
    end

    def deploy_path
      d_path = [parts.path, project.slug, extra_slug].reject(&:blank?).join('/')
      if parts.path.length > 0
        d_path
      else
        '/'+d_path
      end
    end

    def old_deploy_path
      [parts.path, project.slug_was].join('/') if project.slug_changed?
    end

    def project_url
      [base_url, project.slug, extra_slug].reject(&:blank?).join('/')
    end

    def project_asset_url
      [try(:asset_base_url) || base_url, project.slug, extra_slug].reject(&:blank?).join('/')
    end

    def take_screenshots?
      project.build_shell.command?('phantomjs') && !Rails.env.test?
    end

    def logger
      @logger ||= Rails.logger
    end

    def user
      @user ||= project.user
    end

    private

    # Get the parts of the connect url
    def parts
      @parts ||= URI.parse(connect)
    end

    def asset?(path)
      /\.html?$/.match(path).nil? && !/\..{1,5}$/.match(path).nil?
    end
  end
end
