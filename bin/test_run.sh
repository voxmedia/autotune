#!/bin/bash
set -euo pipefail

rm -Rf Gemfile.lock .bundle
bundle install --path vendor/bundle --no-deployment --no-color

export RAILS_ENV=test
bundle exec rake db:reset 
bundle exec rake test

rm -f ./log/*.log
rm -rf ./working
