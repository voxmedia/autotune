#!/bin/bash
set -euo pipefail

rm -Rf Gemfile.lock .bundle
bundle install --path vendor/bundle --no-deployment --no-color

export RAILS_ENV=test
bundle exec rake db:reset 
bundle exec rake test

GEMNASIUM_TOKEN=${GEMNASIUM_TOKEN:-}
if [ ! -z ${GEMNASIUM_TOKEN} ]; then
  echo "Pushing to gemnasium!"
  BRANCH="master" gemnasium dependency_files push
fi
rm -f ./log/*.log
rm -rf ./working
