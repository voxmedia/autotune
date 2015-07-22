require 'autotune/engine'
require 'redis'
require 'uri'

# Top-level autotune module
module Autotune
  # regex for url id
  SLUG_OR_ID_REGEX = /([-\w]+|\d+)/
  # regex for matching auth http header
  AUTH_KEY_RE = /API-KEY\s+auth="?([^"]+)"?/
  # regex for verifying clonable git urls
  REPO_URL_RE = %r{(\w+://)?(.+@)?([\w\.]+)(:[\d]+)?/?(.*)}
  PROJECT_STATUSES = %w(new building updated built broken)
  BLUEPRINT_STATUSES = %w(new updating testing ready broken)
  ROLES = %w(author editor superuser)

  BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'
  BLUEPRINT_BUILD_COMMAND = './autotune-build'

  Config = Struct.new(:working_dir, :build_environment, :setup_environment,
                      :verify_omniauth, :git_ssh, :git_askpass,
                      :redis, :faq_url, :themes)

  class << self
    def redis_pub
      @redis_pub ||= configuration.redis.dup
    end

    def redis_sub
      @redis_sub ||= configuration.redis.dup
    end

    def register_deployer(scheme, deployer_class)
      @deployers ||= {}
      @deployers[scheme.to_sym] = deployer_class
    end

    def deployment(*args, &block)
      @deployments ||= {}
      target = args.first.to_sym
      if block_given?
        @deployments[target] = block
      else
        @deployments[target] = args.last
      end
    end

    def find_deployment(target, project = nil)
      dep = @deployments[target.to_sym]
      if dep.is_a? Proc
        dep.call(project)
      elsif dep.is_a? Hash
        parts = URI.parse(dep['connect'] || dep[:connect])
        unless @deployers.key? parts.scheme.to_sym
          raise "No deployer registered for #{parts.scheme}://"
        end
        @deployers[parts.scheme.to_sym].new(dep)
      else
        dep
      end
    end

    def configure
      yield configuration
    end

    def configuration
      @configuration ||= begin
        Rails.configuration.autotune ||= Config.new
      end
    end
    alias_method :config, :configuration
  end
end

# Load deployers
require 'autotune/deployers/file'
require 'autotune/deployers/s3'
