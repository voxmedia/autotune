require 'uri'
require 'googleauth'
require 'googleauth/user_authorizer'
require 'googleauth/token_store'
require 'google/apis/drive_v2'
require 'fileutils'
require 'json'
require 'date'
require 'stringio'

module Autotune
  # Wrapper around the official google client, for grabbing content from google
  # documents
  class GoogleDocs
    attr_reader :client

    def self.parse_url(url)
      url.match(%r{^(?<base_url>https:\/\/docs.google.com\/(?:a\/(?<domain>[^\/]+)\/)?(?<type>[^\/]+)\/d\/(?<id>[-\w]{25,})).+$})
    end

    def self.key_from_url(url)
      match = parse_url(url)
      match.nil? ? nil : match['id']
    end

    def auth
      @client.authorization
    end

    def initialize(options)
      scope = [
        'https://www.googleapis.com/auth/drive',
        'https://spreadsheets.google.com/feeds/'
      ]
      client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
      token_store = HashTokenStore.new(options[:user_id].to_sym => MultiJson.dump({
        :client_id => ENV['GOOGLE_CLIENT_ID'],
        :access_token => options[:access_token],
        :refresh_token => options[:refresh_token],
        :scope => scope,
        :expiration_time_millis => options[:expires_at].to_i * 1000
      }))
      authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

      credentials = authorizer.get_credentials(options[:user_id])
      if credentials.nil?
        raise AuthorizationError, 'Unable to obtain Google Authorization'
      end

      @client = Google::Apis::DriveV2::DriveService.new
      @client.authorization = credentials

      @_files = {}
      @_spreadsheets = {}
    end

    # Get the contents of a file from Google
    # Takes the url of a Google Drive file and returns an object or string.
    #
    # @param file_id [String] URL
    # @return [Hash,String] file contents
    def get_doc_contents(url, format: nil)
      parts = self.class.parse_url(url)
      case parts['type']
      when 'spreadsheets'
        filename = export_to_file(parts['id'], :xlsx)
        ret = prepare_spreadsheet(filename)
        File.unlink(filename)
      when 'document'
        ret = export(parts['id'], format || :html)
      else
        ret = export(parts['id'], format || :txt)
      end
      ret
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

      # get the file metadata
      resp = @client.get_file(file_id)

      @_files[file_id] = resp
    end

    # Export a file
    # Returns the file contents
    #
    # @param file_id [String] file id
    # @param type [:excel, :text, :html] export type
    # @return [String] file contents
    def export(file_id, type)
      # decide which mimetype we want
      mime = mime_for(type).content_type

      # Create a buffer to write the file contents to`
      io = StringIO.new
      @client.export_file(file_id, mime, :download_dest => io)
      ret = io.string

      # contents
      io.string
    end

    # Export a file and save to disk
    # Returns the local path to the file
    #
    # @param file_id [String] file id
    # @param type [:excel, :text, :html] export type
    # @param filename [String] where to save the spreadsheet
    # @return [String] path to the excel file
    def export_to_file(file_id, type, filename = nil)
      # decide which mimetype we want
      mime = mime_for(type).content_type

      filename ||= "#{Dir.tmpdir}/googledoc-#{file_id}-#{Time.now.to_i}.#{type}"

      @client.export_file(file_id, mime, :download_dest => filename)

      filename
    end

    # Make a copy of a Google Drive file
    #
    # @param file_id [String] file id
    # @param title [String] title for the newly created file
    # @return [Hash] hash containing the id/key and url of the new file
    def copy(file_id, title = nil, visibility = :private)
      if title.nil?
        copied_file = Google::Apis::DriveV2::File.new
      else
        copied_file = Google::Apis::DriveV2::File.new(
          :title => title, :writers_can_share => true)
      end
      new_file = @client.copy_file(
        file_id,
        copied_file,
        :visibility => visibility.to_s.upcase
      )

      { :id => new_file.id, :url => new_file.alternate_link }
    end
    alias_method :copy_doc, :copy

    def share_with_domain(file_id, domain)
      unless check_permission(file_id, domain)
        insert_permission(file_id, domain, 'domain', 'writer')
      end
    end

    def check_permission(file_id, domain)
      perms = @client.list_permissions(file_id)

      has_permission = false
      perms.items.each do |perm|
        if perm.type == 'domain' && perm.domain == domain
          has_permission = true
        elsif perm.type == 'anyone'
          has_permission = true
        end
      end

      has_permission
    end

    def insert_permission(file_id, value, perm_type, role)
      new_permission = Google::Apis::DriveV2::Permission.new(
        :value => value, :type => perm_type, :role => role
      )
      @client.insert_permission(file_id, new_permission)
    end

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
      data
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
      return [] if header.nil?
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

    class GoogleDriveError < StandardError; end
    class CreateError < GoogleDriveError; end
    class ConfigurationError < GoogleDriveError; end
    class AuthorizationError < GoogleDriveError; end
    class ClientError < GoogleDriveError; end
    class Unauthorized < ClientError; end
    class Forbidden < ClientError; end
    class DoesNotExist < ClientError; end

    class HashTokenStore < Google::Auth::TokenStore
      def initialize(tokens)
        @store = tokens.with_indifferent_access
      end

      def load(id)
        @store[id]
      end

      def store(id, token)
        @store[id] = token
      end

      def delete(id)
        @store.delete(id)
      end

      def to_h
        @store
      end
    end

    private

    def handle_errors(result)
      puts result
      return if result.success?
      # die if there's an error
      if result.response.status >= 500
        ex = GoogleDriveError
      elsif result.response.status == 404
        ex = DoesNotExist
      elsif result.response.status == 401
        ex = Unauthorized
      elsif result.response.status == 403
        ex = Forbidden
      elsif result.response.status >= 400
        ex = ClientError
      end
      raise ex, result.error_message
    end
  end
end
