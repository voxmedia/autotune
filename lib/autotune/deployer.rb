require 'uri'

module Autotune
  # Autotune blueprint base deployer
  class Deployer
    attr_accessor :base_url, :asset_base_url, :connect

    # Create a new deployer
    def initialize(**kwargs)
      @connect  = kwargs['connect'] || kwargs[:connect]
      @base_url = kwargs['base_url'] || kwargs[:base_url]
      @asset_base_url = kwargs['asset_base_url'] || kwargs[:asset_base_url] || @base_url
    end

    # Deploy an entire directory
    def deploy(_source, _project)
      raise NotImplementedError
    end

    # Deploy one file
    def deploy_file(_dir, _project, _path)
      raise NotImplementedError
    end

    # Hook for adjusting data and files before build
    def before_build(build_data, project)
      build_data['base_url'] = url_for(project, project.slug)
      build_data['asset_base_url'] = build_data['base_url']
    end

    # Get the url to a file
    def url_for(_project, path)
      ret = [base_url, path].join('/')
      ret += '/' if File.extname(path).empty?
      ret
    end

    private

    # Get the parts of the connect url
    def parts
      @parts ||= URI.parse(connect)
    end
  end
end
