require 'autotune/engine'
require 'redis'

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
                      :preview, :publish, :media,
                      :verify_omniauth, :git_ssh, :git_askpass,
                      :faq_url, :themes)

  class << self
    attr_writer :redis
    def redis_pub
      @redis_pub ||= @redis.dup
    end

    def redis_sub
      @redis_sub ||= @redis.dup
    end
  end
end
