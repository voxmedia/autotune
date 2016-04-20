#!/bin/bash
set -euo pipefail

rm -Rf Gemfile.lock .bundle
env
bundle install --path vendor/bundle --no-deployment --no-color

export RAILS_ENV=test
env
bundle exec rake db:reset 
# Don't use bundle exec here because it's gonna hijack our GEM_PATH, which
# will eventually result in WorkDir::Repo not being able to find bundler itself
# when it wants to call it
rake test
