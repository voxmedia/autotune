#!/bin/bash
# This is the file that Docker executes by default when the container runs.
# In this case, that means setting up and executing the test suite
set -euo pipefail

export REDIS_URL="redis://$AUTOTUNE_REDIS_PORT_6379_TCP_ADDR"

bundle install --path vendor/bundle
bundle exec rake db:reset 
rake test
