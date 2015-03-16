require 'autotune/engine'

# Top-level autotune module
module Autotune
  # regex for url id
  SLUG_OR_ID_REGEX = /([-\w]+|\d+)/
  # regex for matching auth http header
  AUTH_KEY_RE = /API-KEY\s+auth="?([^"]+)"?/
  # regex for verifying clonable git urls
  REPO_URL_RE = %r{(\w+://)?(.+@)?([\w\.]+)(:[\d]+)?/?(.*)}
end
