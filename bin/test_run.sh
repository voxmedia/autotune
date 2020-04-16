#!/bin/bash
set -euo pipefail

rm -Rf Gemfile.lock .bundle
bundle install --path vendor/bundle --no-deployment --no-color

export RAILS_ENV=test
bundle exec rake db:reset
bundle exec rake test

# TODO: should we also do these?
#   npm install
#   npm test

rm -f ./log/*.log
rm -rf ./working
