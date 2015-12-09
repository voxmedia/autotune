require 'work_dir'
require 'date'
require 'logger'
require 'stringio'
# require "google/api_client"
# require "google_drive"

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    unique_job :with => :payload

    def perform(project, target: 'preview')
      # env_vars = Rails.configuration.autotune.build_environment

      # Creates a session. This will prompt the credential via command line for the
      # first time and save it to ./stored_token.json file for later usages.
      #
      # If you are developing a Web app, and you want to ask the user to log in in
      # the Web app instead of via command line, follow the example code in:
      # http://gimite.net/doc/google-drive-ruby/GoogleDrive.html#method-c-login_with_oauth
      # session = GoogleDrive.saved_session("./stored_token.json", nil, env_vars['GOOGLE_CLIENT_ID'], env_vars['GOOGLE_CLIENT_SECRET'])
      #
      # # Gets list of remote files.
      # session.files.each do |file|
      #   p file.title
      # end
      #
      # client = Google::APIClient.new
      # auth = client.authorization
      # # Follow "Create a client ID and client secret" in
      # # https://developers.google.com/drive/web/auth/web-server] to get a client ID and client secret.
      # auth.client_id = env_vars['GOOGLE_CLIENT_ID']
      # auth.client_secret = env_vars['GOOGLE_CLIENT_SECRET']
      # # auth.scope =
      # #     "https://www.googleapis.com/auth/drive " +
      # #     "https://spreadsheets.google.com/feeds/"
      # #
      # # auth.code = '4/FykSU0wxCbNE_1crtY5qE60gqlViujfwfBR-CVAkj3A'
      # auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
      #
      # begin
      #   # client.authorization.fetch_access_token!
      #   puts client.authorization.as_json
      #   session = GoogleDrive.login_with_oauth(client.authorization.access_token)
      #   ws = session.spreadsheet_by_key("1vvO35_UD3HVUA0Ii1GRUvdl4_mz54aKdhDS_TO3h54g").worksheets[0]
      #   puts ws.as_json
      #   # return client.authorization
      # rescue Signet::AuthorizationError
      #   raise CodeExchangeError.new(nil)
      # end

      # Setup a new logger that logs to a string. The resulting log will
      # be saved to the output field of the project.
      out = StringIO.new
      outlogger = Logger.new out
      outlogger.formatter = proc do |severity, datetime, _progname, msg|
        "#{datetime.strftime('%b %e %H:%M %Z')}\t#{severity}\t#{msg}\n"
      end

      # Reset any previous error messages:
      project.meta.delete('error_message')

      # Create a new repo object based on the projects working dir
      repo = WorkDir.repo(project.working_dir,
                          Rails.configuration.autotune.build_environment)

      # Make sure the repo exists and is up to date (if necessary)
      raise 'Missing files!' unless repo.exist?

      # Add a few extras to the build data
      build_data = project.data.deep_dup
      build_data.update(
        'title' => project.title,
        'slug' => project.slug,
        'theme' => project.theme.value)

      # Get the deployer object
      deployer = Autotune.new_deployer(
        target.to_sym, project, :logger => outlogger)

      # Run the before build deployer hook
      deployer.before_build(build_data, repo.env)

      # Run the build
      repo.working_dir do
        outlogger.info(repo.cmd(
          BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json))
      end

      # Upload build
      deployer.deploy(project.full_deploy_dir)

      # Create screenshots (has to happen after upload)
      phantom = WorkDir.phantom(project.full_deploy_dir)
      if phantom.phantomjs? && !Rails.env.test?
        begin
          url = deployer.url_for('/')
          phantom.capture_screenshot(get_full_url(url))

          # Upload screens
          phantom.screenshots.each do |filename|
            deployer.deploy_file(project.full_deploy_dir, filename)
          end
        rescue ::WorkDir::CommandError => exc
          logger.error(exc.message)
          outlogger.warn(exc.message)
        end
      end

      # Set status and save project
      project.published_at = DateTime.current if target.to_sym == :publish
      project.status = 'built'
    rescue => exc
      # If the command failed, raise a red flag
      if exc.is_a? ::WorkDir::CommandError
        msg = exc.message
      else
        msg = exc.message + "\n" + exc.backtrace.join("\n")
      end
      logger.error(msg)
      outlogger.error(msg)
      project.status = 'broken'
      raise
    ensure
      # Always make sure to save the log and the project
      outlogger.close
      project.output = out.try(:string)
      project.save!
    end

    private

    def get_full_url(url)
      return url if url.start_with?('http')
      url.start_with?('//') ? 'http:' + url : 'http://localhost:3000' + url
    end
  end
end
