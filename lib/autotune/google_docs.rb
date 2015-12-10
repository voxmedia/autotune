# require 'google_drive'
# require 'oauth2'
# require 'rubyXL'

module Autotune

  class GoogleDocsParser

    def initialize(document)
      @doc = document
    end

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
