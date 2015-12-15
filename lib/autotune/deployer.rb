require 'uri'
require 'google_drive'
require 'google/api_client'
require 'oauth2'
require 'autotune/google_docs'
require 'json'

module Autotune
  # Autotune blueprint base deployer
  class Deployer
    attr_accessor :base_url, :connect, :project, :slug
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
      if build_data['google_doc_url']
        spreadsheet_key = build_data['google_doc_url'].match(/[-\w]{25,}/).to_s
        cur_user = User.find(project.meta['current_user'])
        current_auth = cur_user.authorizations.find_by!(:provider => 'google_oauth2')

        client = Google::APIClient.new
        auth = client.authorization
        auth.client_id = ENV["GOOGLE_CLIENT_ID"]
        auth.client_secret = ENV["GOOGLE_CLIENT_SECRET"]
        auth.scope =
            "https://www.googleapis.com/auth/drive " +
            "https://spreadsheets.google.com/feeds/"
        # auth.redirect_uri = "http://example.com/redirect"
        auth.refresh_token = current_auth.credentials['refresh_token']
        auth.fetch_access_token!

        google_session = GoogleDrive.login_with_oauth(auth.access_token)
        spread_sheet = google_session.spreadsheet_by_key(spreadsheet_key)
        export_path = File.join(project.working_dir, 'data/'+spread_sheet.title+'.xls').to_s
        spread_sheet.export_as_file(export_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        new_doc = GoogleDocsParser.new(spread_sheet.title+'.xls')
        project.data['google_data'] = new_doc.prepare_spreadsheet(export_path)
        build_data['google_doc_data'] = project.data['google_data']
      end

      build_data['base_url'] = project_url
      build_data['asset_base_url'] = project_asset_url

      export_path_at = File.join(project.working_dir, 'data/autotune.json').to_s
      File.open(export_path_at, 'w') do |f|
        f.puts JSON.pretty_generate(build_data)
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
      [parts.path, slug || project.slug].join('/')
    end

    def old_deploy_path
      [parts.path, project.slug_was].join('/') if project.slug_changed?
    end

    def project_url
      [base_url, slug || project.slug].join('/')
    end

    def project_asset_url
      [try(:asset_base_url) || base_url, slug || project.slug].join('/')
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
