require 'test_helper'
require 'autotune/google_docs'

# Test the WorkDir classes; Repo and Snapshot
module Autotune
  class GoogleDocsTest < ActiveSupport::TestCase
    test 'get public doc contents' do
      VCR.use_cassette('get_spreadsheet') do
        client = GoogleDocs.new

        puts client.get_doc_contents('https://docs.google.com/spreadsheets/d/1jEpEjCcGkcJrMrnuXecnwiojpY0KSklUSBB183BSjmM')
      end
    end
  end
end
