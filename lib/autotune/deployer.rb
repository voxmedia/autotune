require 'uri'
require 'autotune/google_docs'
require 'date'

module Autotune
  # Autotune blueprint base deployer
  class Deployer
    attr_accessor :base_url, :connect, :asset_base_url, :asset_connect, :project, :extra_slug, :ignore_slug
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

    # Hook for preparing the deployment target before the build job is queued.
    # Project instance is saved after this method is run.
    def prep_target
      # retrieve and cache google doc data now so we can handle errors
      # immediately instead of in the job
      build_data = project.data
      if (build_data['google_doc_url'].present? || build_data['google_docs'].present?) && google_client.present?
        if build_data['google_docs'].present?
          build_data['google_docs'].each do |url|
            google_doc_contents(url)
          end
        elsif build_data['google_doc_url'].present?
          google_doc_contents(build_data['google_doc_url'])
        end
      end
    rescue GoogleDocs::Unauthorized => exc
      logger.error(exc)
      raise Autotune::Unauthorized, 'Unable to retrieve Google Doc because user session expired.'
    rescue GoogleDocs::Forbidden => exc
      logger.error(exc)
      raise Autotune::Forbidden, 'Unable to retrieve Google Doc because user does not have access.'
    rescue OAuth2::Error => exc
      if exc.code == 'invalid_grant'
        raise Autotune::Unauthorized, "Google Auth: #{exc.description}"
      else
        raise
      end
    end

    def after_prep_target
      if Rails.configuration.autotune.deployer_after_prep_target.is_a?(Proc)
        Rails.configuration.autotune.deployer_after_prep_target.call(self)
      end
    end

    # Hook for adjusting data and files before build. Project
    # instance is saved after this method runs.
    def before_build(build_data, _env)
      if build_data['google_docs'].present?
        build_data['google_docs'].map! do |url|
          { 'url' => url, 'data' => google_doc_contents(url) }
        end
      elsif build_data['google_doc_url'].present?
        build_data['google_doc_data'] = google_doc_contents(build_data['google_doc_url'])
      end

      build_data['title'] = project.title if build_data['title'].blank?
      build_data['slug'] = project.slug if build_data['slug'].blank?
      build_data['available_themes'] = Theme.all.pluck(:slug) if build_data['available_themes'].blank?
      build_data['theme_data'] = Theme.full_theme_data if build_data['theme_data'].blank?
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
      project.meta['error_message'] = 'Unable to retrieve Google Doc because user session expired.'

      raise
    rescue GoogleDocs::Forbidden => exc
      logger.error(exc)
      project.meta['error_message'] = 'Unable to retrieve Google Doc because user does not have access.'

      raise
    end

    def after_before_build(build_data, env)
      if Rails.configuration.autotune.deployer_after_before_build.is_a?(Proc)
        Rails.configuration.autotune.deployer_after_before_build.call(self, build_data, env)
      end
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
      p = build_path_from_parts(parts.path, project.slug)
      p =~ %r{^/} ? p : "/#{p}"
    end

    def old_deploy_path
      p = build_path_from_parts(parts.path, project.slug_was)
      p =~ %r{^/} ? p : "/#{p}"
    end

    def asset_deploy_path
      if asset_connect.present?
        p = build_path_from_parts(asset_parts.path, project.slug)
        p =~ %r{^/} ? p : "/#{p}"
      else
        deploy_path
      end
    end

    def old_asset_deploy_path
      if asset_connect.present?
        p = build_path_from_parts(asset_parts.path, project.slug_was)
        p =~ %r{^/} ? p : "/#{p}"
      else
        old_deploy_path
      end
    end

    def project_url
      build_path_from_parts(base_url, project.slug)
    end

    def project_asset_url
      if asset_base_url.present?
        build_path_from_parts(asset_base_url, project.slug)
      else
        project_url
      end
    end

    def take_screenshots?
      project.build_shell.command?('phantomjs') && !Rails.env.test?
    end

    def logger
      @logger ||= Rails.logger
    end

    def user
      return @user if defined?(@user)
      @user = project.user if project.present? && project.respond_to?(:user)
    end

    private

    def build_path_from_parts(path, slug)
      path_parts = []
      path_parts << path if path.present?
      path_parts << slug if !ignore_slug && slug.present?
      path_parts << extra_slug if extra_slug.present?
      path_parts.join('/')
    end

    # Get the parts of the connect url
    def parts
      @parts ||= URI.parse(connect)
    end

    def asset_parts
      @asset_parts ||=
        if asset_connect.present?
          URI.parse(asset_connect)
        else
          parts
        end
    end

    def asset?(path)
      /\.html?$/.match(path).nil? && !/\..{1,5}$/.match(path).nil?
    end

    def google_client
      return @google_client if defined? @google_client

      return if user.blank?

      current_auth = user.authorizations.find_by!(:provider => 'google_oauth2')

      google_client = GoogleDocs.new(
        :user_id => current_auth.uid,
        :refresh_token => current_auth.credentials['refresh_token'],
        :access_token => current_auth.credentials['token'],
        :expires_at => current_auth.credentials['expires_at']
      )

      current_auth.credentials['refresh_token'] = google_client.auth.refresh_token
      current_auth.credentials['token'] = google_client.auth.access_token
      current_auth.credentials['expires_at'] = google_client.auth.expires_at
      current_auth.save!

      @google_client = google_client
    end

    def google_doc_contents(url)
      return if google_client.blank?

      doc_key = GoogleDocs.key_from_url(url)
      return if doc_key.blank?

      cache_key = "googledoc#{doc_key}"

      resp = google_client.find(doc_key)
      cache_value = nil
      if Rails.cache.exist?(cache_key)
        cache_value = Rails.cache.read(cache_key)
        needs_update = cache_value['version'] && resp['version'] != cache_value['version']
      else
        needs_update = true
      end

      # TODO: needs test coverage
      if needs_update
        google_client.share_with_domain(doc_key, Autotune.configuration.google_auth_domain)
        ret = google_client.get_doc_contents(url)
        Rails.cache.write(cache_key, 'ss_data' => ret, 'version' => resp['version'])
      else
        ret = (cache_value || Rails.cache.read(cache_key))['ss_data']
      end

      ret
    end
  end
end
