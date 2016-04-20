#!/bin/bash
set -euo pipefail

bundle install --path vendor/bundle
bundle exec rake db:reset  RAILS_ENV=test
bundle exec rake test
