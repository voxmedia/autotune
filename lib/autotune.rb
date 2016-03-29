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
  PROJECT_PUB_STATUSES = %w(draft published)
  BLUEPRINT_STATUSES = %w(new updating testing ready broken)
  BLUEPRINT_TYPES = %w(graphic app)
  EDITABLE_SLUG_BLUEPRINT_TYPES = %w(app)
  ROLES = %w(none author editor superuser)

  BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'
  BLUEPRINT_BUILD_COMMAND = './autotune-build'

  Config = Struct.new(:working_dir, :build_environment, :setup_environment,
                      :verify_omniauth, :verify_authorization_header,
                      :google_auth_enabled, :google_auth_domain,
                      :git_ssh, :git_askpass,
                      :redis, :faq_url, :themes)

  class << self
    delegate :redis, :to => :configuration

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

    def new_deployer(target, project = nil, **opts)
      dep = @deployments[target.to_sym]
      dep = dep.call(project, opts) if dep.is_a? Proc
      if dep.is_a? Hash
        parts = URI.parse(dep[:connect])
        unless @deployers.key? parts.scheme.to_sym
          raise "No deployer registered for #{parts.scheme}://"
        end
        @deployers[parts.scheme.to_sym].new(
          dep.dup.update(:project => project).update(opts))
      else
        dep
      end
    rescue => exc
      Rails.logger.error exc.message + "\n" + exc.backtrace.join("\n")
      raise
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
