require 'uri'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'
require 'json'

module Autotune

  class GoogleDocs

    attr_reader :client

    def initialize(current_auth)
      @client = Google::APIClient.new
      auth = client.authorization
      auth.client_id = ENV["GOOGLE_CLIENT_ID"]
      auth.client_secret = ENV["GOOGLE_CLIENT_SECRET"]
      auth.scope =
          "https://www.googleapis.com/auth/drive " +
          "https://spreadsheets.google.com/feeds/"
      # auth.redirect_uri = "http://example.com/redirect"
      auth.refresh_token = current_auth.credentials['refresh_token']
      auth.fetch_access_token!

      @_files = {}
      @_spreadsheets = {}
    end

    def create_spreadsheet
      drive = @client.discovered_api('drive', 'v2')
      # 'application/vnd.google-apps.drive-sdk'
      file = drive.files.insert.request_schema.new({
        'title' => 'My spreadsheet',
        'description' => 'A test spreadsheet',
        'mimeType' => 'application/vnd.google-apps.drive-sdk'
      })

      # media = Google::APIClient::UploadIO.new('document.csv', "text/csv")
      # pp media
      result = @client.execute(
        :api_method => drive.files.insert,
        :body_object => file,
        # :media => media,
        :parameters => {
          'uploadType' => 'multipart',
          # 'convert' => true,
          'alt' => 'json'})

      fail GoogleDriveError, result.error_message if result.error?

      # Pretty print the API result
      pp result.data.to_hash
    end


    # Find a Google Drive file
    # Takes the key of a Google Drive file and returns a hash of meta data. The returned hash is
    # formatted as a
    # {Google Drive resource}[https://developers.google.com/drive/v2/reference/files#resource].
    #
    # @param file_id [String] file id
    # @return [Hash] file meta data
    def find(file_id)
      return @_files[file_id] unless @_files[file_id].nil?

      drive = @client.discovered_api('drive', 'v2')

      # get the file metadata
      resp = @client.execute(
        api_method: drive.files.get,
        parameters: { fileId: file_id })

      # die if there's an error
      fail GoogleDriveError, resp.error_message if resp.error?

      @_files[file_id] = resp.data
    end

    def watch(file_id)
      # return @_files[file_id] unless @_files[file_id].nil?

      drive = @client.discovered_api('drive', 'v2')
      channel_address = "https://staging.autotune.voxmedia.com/projects/";
      channel_id = 'id-'+file_id;

      # get the file metadata
      resp = @client.execute(
        api_method: drive.files.watch,
        :body_object => { 'id' => channel_id, 'type' => 'web_hook', 'address' => channel_address },
        parameters: { fileId: file_id })
      pp resp
      if resp.status == 200
        puts resp.data
        return resp.data
      else
        puts "An error occurred: #{result.data['error']['message']}"
      end

      # die if there's an error
      fail GoogleDriveError, resp.error_message if resp.error?

      @_files[file_id] = resp.data
    end

    # Export a file
    # Returns the file contents
    #
    # @param file_id [String] file id
    # @param type [:excel, :text, :html] export type
    # @return [String] file contents
    def export(file_id, type)
      # watch(file_id)
      list_resp = find(file_id)

      # decide which mimetype we want
      mime = mime_for(type).content_type

      # Grab the export url.
      if list_resp['exportLinks'] && list_resp['exportLinks'][mime]
        uri = list_resp['exportLinks'][mime]
      else
        raise "Google doesn't support exporting file id #{file_id} to #{type}"
      end

      # get the export
      get_resp = @client.execute(uri: uri)

      # die if there's an error
      fail GoogleDriveError, get_resp.error_message if get_resp.error?

      # contents
      get_resp.body
    end

    # Export a file and save to disk
    # Returns the local path to the file
    #
    # @param file_id [String] file id
    # @param type [:excel, :text, :html] export type
    # @param filename [String] where to save the spreadsheet
    # @return [String] path to the excel file
    def export_to_file(file_id, type, filename = nil)
      contents = export(file_id, type)

      if filename.nil?
        # get a temporary file. The export is binary, so open the tempfile in
        # write binary mode
        fp = Tempfile.create(
          ['googledoc', ".#{type}"], binmode: mime_for(type.to_s).binary?)
        filename = fp.path
        fp.write(contents)
        fp.close
      else
        open(filename, 'wb') { |f| f.write(contents) }
      end
      filename
    end

    # Make a copy of a Google Drive file
    #
    # @param file_id [String] file id
    # @param title [String] title for the newly created file
    # @return [Hash] hash containing the id/key and url of the new file
    def copy(file_id, title = nil, visibility = :private)
      drive = @client.discovered_api('drive', 'v2')

      if title.nil?
        copied_file = drive.files.copy.request_schema.new
      else
        copied_file = drive.files.copy.request_schema.new('title' => title)
      end
      cp_resp = @client.execute(
        api_method: drive.files.copy,
        body_object: copied_file,
        parameters: { fileId: file_id, visibility: visibility.to_s.upcase })

      if cp_resp.error?
        fail CreateError, cp_resp.error_message
      else
        return { id: cp_resp.data['id'], url: cp_resp.data['alternateLink'] }
      end
    end
    alias_method :copy_doc, :copy

    # Get the mime type from a file extension
    #
    # @param extension [String] file ext
    # @return [String, nil] mime type for the file
    def mime_for(extension)
      MIME::Types.of(extension.to_s).first
    end

    ## Spreadsheet utilities

    # Parse a spreadsheet
    # Reduces the spreadsheet to a no-frills hash, suitable for serializing and passing around.
    #
    # @param filename [String] path to xls file
    # @return [Hash] spreadsheet contents
    def prepare_spreadsheet(filename)
      # open the file with RubyXL
      xls = RubyXL::Parser.parse(filename)
      data = {}
      xls.worksheets.each do |sheet|
        title = sheet.sheet_name
        # if the sheet is called microcopy, copy or ends with copy, we assume
        # the first column contains keys and the second contains values.
        # Like tarbell.
        if %w(microcopy copy).include?(title.downcase) ||
            title.downcase =~ /[ -_]copy$/
          data[title] = load_microcopy(sheet.extract_data)
        else
          # otherwise parse the sheet into a hash
          data[title] = load_table(sheet.extract_data)
        end
      end
      return data
    end

    # Take a two-dimensional array from a spreadsheet and create a hash. The first
    # column is used as the key, and the second column is the value. If the key
    # occurs more than once, the value becomes an array to hold all the values
    # associated with the key.
    #
    # @param table [Array<Array>] 2d array of cell values
    # @return [Hash] spreadsheet contents
    def load_microcopy(table)
      data = {}
      table.each_with_index do |row, i|
        next if i == 0 # skip the header row
        next if row.nil? || row.length < 2 || row[0].nil? # skip empty, incomplete or blank rows
        # Did we already create this key?
        if data.keys.include? row[0]
          # if the key name is reused, create an array with all the entries
          if data[row[0]].is_a? Array
            data[row[0]] << row[1]
          else
            data[row[0]] = [data[row[0]], row[1]]
          end
        else
          # add this row's key and value to the hash
          data[row[0]] = row[1]
        end
      end
      data
    end

    # Take a two-dimensional array from a spreadsheet and create an array of hashes.
    #
    # @param table [Array<Array>] 2d array of cell values
    # @return [Array<Hash>] spreadsheet contents
    def load_table(table)
      return [] if table.length < 2
      header = table.shift # Get the header row
      # remove blank rows
      table.reject! do |row|
        row.nil? || row
          .map { |r| r.nil? || r.to_s.strip.empty? }
          .reduce(true) { |m, col| m && col }
      end
      table.map do |row|
        # zip headers with current row, convert it to a hash
        header.zip(row).to_h unless row.nil?
      end
    end

  end
end
