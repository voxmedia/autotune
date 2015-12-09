require_dependency 'autotune/application_controller'
require 'google_drive'
require 'google_drive/google_docs'
require 'oauth2'

module Autotune
  class DocumentsController < ApplicationController
    before_filter :google_drive_login, :only => [:list_google_docs]

    env_vars = Rails.configuration.autotune.build_environment

    GOOGLE_CLIENT_ID = env_vars['GOOGLE_CLIENT_ID']
    GOOGLE_CLIENT_SECRET = env_vars['GOOGLE_CLIENT_SECRET']
    GOOGLE_CLIENT_REDIRECT_URI = "http://localhost:3000/oauth2callback"
    # you better put constant like above in environments file, I have put it just for simplicity
    def list_google_docs
      puts 'list google docs'
      puts 'session', session.as_json
      google_session = GoogleDrive.login_with_oauth(session[:google_token])
      # puts 'files', google_session.files
      @google_docs = []
      for file in google_session.files
        puts file.title
        @google_docs << file.title
      end
    end

    def download_google_docs
      file_name = params[:doc_upload]
      file_name_session = GoogleDrive.login_with_oauth(session[:google_token])
      file_path = Rails.root.join('tmp',"doc_#{file_name_session}")
      file = google_session.file_by_title(file_name)
      file.download_to_file(file_path)
      redirect_to list_google_doc_path
    end

    def set_google_drive_token
      google_doc = GoogleDrive::GoogleDocs.new(GOOGLE_CLIENT_ID,GOOGLE_CLIENT_SECRET,
                  GOOGLE_CLIENT_REDIRECT_URI)
      oauth_client = google_doc.create_google_client
      puts 'params', params.as_json
      puts 'oauth client', oauth_client.as_json
      auth_token = oauth_client.auth_code.get_token(params[:code],
                   :redirect_uri => GOOGLE_CLIENT_REDIRECT_URI)
      puts auth_token
      session[:google_token] = auth_token.token if auth_token
      puts session.as_json
      redirect_to list_google_doc_path
    end

    def google_drive_login
      puts 'getting to google drive login'
      unless session[:google_token].present?
        puts 'does not have token'
        google_drive = GoogleDrive::GoogleDocs.new(GOOGLE_CLIENT_ID,GOOGLE_CLIENT_SECRET,
                       GOOGLE_CLIENT_REDIRECT_URI)
        auth_url = google_drive.set_google_authorize_url
        redirect_to auth_url
      else
        redirect_to list_google_doc_path
      end
    end
  end
end
