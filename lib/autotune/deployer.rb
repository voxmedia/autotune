require 'uri'
require 'google_drive'
require 'google/api_client'
require 'oauth2'

module Autotune
  # Autotune blueprint base deployer
  class Deployer
    attr_accessor :base_url, :connect, :project
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
    def before_build(build_data, _env)
      # pp build_data.as_json
      if build_data['google_doc_url']
        spreadsheet_key = build_data['google_doc_url'].match(/[-\w]{25,}/).to_s
        token = project.user.authorizations.find_by!(:provider => 'google_oauth2').credentials['token']
        # project.user.authorizations.find_by!(:provider => 'google_oauth2').credentials['scope'] = "https://www.googleapis.com/auth/drive " + "https://spreadsheets.google.com/feeds/"

        google_session = GoogleDrive.login_with_oauth(token)
        # pp project.user.authorizations
        # pp token
        # pp google_session
        spread_sheet = google_session.spreadsheet_by_key(spreadsheet_key)
        # .worksheets[0]
        pp spread_sheet
        pp spread_sheet.export_as_string("text/csv")
      end

      build_data['base_url'] = project_url
      build_data['asset_base_url'] = project_asset_url
    end

    # Hook to do stuff after a project is deleted
    def delete!(*)
      raise NotImplementedError
    end

    # Hook to do stuff after a project is deleted
    def delete!
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

    # def deploy_path
    #   d_path = [parts.path, project.slug].join('/')
    #   if parts.scheme == 's3'
    #     d_path += '/'
    #   end
    #   d_path
    # end
    #
    # def project_url
    #   proj_url = [base_url, project.slug].join('/')
    #   if parts.scheme == 's3'
    #     proj_url += '/'
    #   end
    #   proj_url
    # end
    def deploy_path
      [parts.path, project.slug].join('/')
    end

    def old_deploy_path
      [parts.path, project.slug_was].join('/') if project.slug_changed?
    end

    def project_url
      [base_url, project.slug].join('/')
    end

    def project_asset_url
      asset = [try(:asset_base_url) || base_url, project.slug].join('/')
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
