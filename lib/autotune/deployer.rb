require 'uri'
require 'autotune/google_docs'
require 'date'

module Autotune
  # Autotune blueprint base deployer
  class Deployer
    attr_accessor :base_url, :connect, :project, :extra_slug
    attr_writer :logger

    # Create a new deployer
    def initialize(kwargs)
      kwargs.each do |k, v|
        send "#{k}=".to_sym, v
      end
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
    def before_build(build_data, _env, current_user = nil)
      if build_data['google_doc_url'] && current_user
        current_auth = current_user.authorizations.find_by!(:provider => 'google_oauth2')
        if current_user
          google_client = GoogleDocs.new(current_auth)
          spreadsheet_key = build_data['google_doc_url'].match(/[-\w]{25,}/).to_s
          resp = google_client.find(spreadsheet_key)
          cache_key = "googledoc#{spreadsheet_key}"
          needs_update = false

          if Rails.cache.exist?(cache_key)
            if Rails.cache.read(cache_key)['version'] && resp['version'] != Rails.cache.read(cache_key)['version']
              needs_update = true
            end
          else
            needs_update = true
          end

          if needs_update
            google_client.share_with_domain(spreadsheet_key, Autotune.configuration.google_auth_domain)
            exp_file = google_client.export_to_file(spreadsheet_key, 'xlsx')
            ss_data = google_client.prepare_spreadsheet(exp_file)
            build_data['google_doc_data'] = ss_data
            Rails.cache.write(cache_key, {'ss_data' => ss_data, 'version' => resp['version']})
          else
            build_data['google_doc_data'] = Rails.cache.read(cache_key)['ss_data']
          end
        end
      end

      build_data['base_url'] = project_url
      build_data['asset_base_url'] = project_asset_url
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

    def logger
      @logger ||= Rails.logger
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
