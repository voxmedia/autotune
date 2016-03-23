require 'json'
# Top level Autotune namespace
module Autotune
  VERSION = JSON.load(open(File.expand_path('../../../package.json', __FILE__)))['version']
end
