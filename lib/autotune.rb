require 'autotune/engine'

# Top-level autotune module
module Autotune
  # regex for url id
  SLUG_OR_ID_REGEX = /([-\w]+|\d+)/
  # regex for matching auth http header
  AUTH_KEY_RE = /API-KEY\s+auth="?([^"]+)"?/
  # regex for verifying clonable git urls
  REPO_URL_RE = %r{(\w+://)?(.+@)?([\w\.]+)(:[\d]+)?/?(.*)}
  PROJECT_STATUSES = %w(new updating updated building built broken)
  BLUEPRINT_STATUSES = %w(new updating testing ready broken)
  ROLES = %w(author editor superuser)

  Config = Struct.new(:working_dir, :build_environment, :setup_environment,
                      :preview, :publish, :media,
                      :verify_omniauth, :git_ssh, :git_askpass)
end
