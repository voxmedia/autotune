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
  BLUEPRINT_STATUSES = %w(new updating built broken)
  BLUEPRINT_MODES = %w(testing ready)
  THEME_STATUSES = %w(new updating ready broken)
  BLUEPRINT_TYPES = %w(graphic app)
  EDITABLE_SLUG_BLUEPRINT_TYPES = %w(app)
  ROLES = %w(none author editor designer superuser)
  BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'
  BLUEPRINT_BUILD_COMMAND = './autotune-build'
  # add a time buffer to account for processing
  MESSAGE_BUFFER = 0.5

  Config = Struct.new(:working_dir, :build_environment, :setup_environment,
                      :verify_omniauth, :verify_authorization_header,
                      :google_auth_enabled, :google_auth_domain,
                      :git_ssh, :git_askpass,
                      :redis, :faq_url, :generic_theme, :theme_meta_data, :get_theme_data)

  class << self
    delegate :redis, :to => :configuration

    def redis_sub
      @redis_sub ||= configuration.redis.dup
    end

    def root
      Pathname.new(File.expand_path('../..', __FILE__))
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

    def can_message?
      Autotune.redis.present?
    end

    def send_message(type, data)
      ensure_redis
      dt = DateTime.current
      payload = { 'type' => type, 'time' => dt.utc.to_f, 'data' => data }
      redis.zadd('messages', dt.utc.to_f, payload.to_json)
      redis.publish type, data.to_json
      purge_messages :older_than => dt - 24.hours
      dt
    end

    def purge_messages(older_than: nil)
      ensure_redis
      if older_than.nil?
        redis.del('messages')
      else
        redis.zremrangebyscore('messages', '-inf', older_than.utc.to_f)
      end
    end

    def messages(since: nil, type: nil)
      ensure_redis

      if since.nil?
        results = redis.zrange('messages', 0, 1000)
      else
        results = redis.zrangebyscore('messages', since.utc.to_f - MESSAGE_BUFFER, '+inf')
      end

      results.map! { |d| ActiveSupport::JSON.decode(d) }

      if type.is_a?(String)
        results.select { |m| m['type'] == type }
      else
        results
      end
    end

    private

    def ensure_redis
      raise 'Redis is not configured' if redis.nil?
    end
  end
end

# Load deployers
require 'autotune/deployers/file'
require 'autotune/deployers/s3'

