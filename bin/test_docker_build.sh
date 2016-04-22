#!/bin/bash
set -euo pipefail

if [ -z ${SSH_KEY_PATH+x} ]; then
	export SSH_KEY_PATH=~/.ssh/id_rsa
else
	# For Jenkins, when you have to manually pass in a key
	chmod 700 $SSH_KEY_PATH
fi

docker-compose build
# Force GEM_PATH so that down the line, _ORIGINAL_GEM_PATH is available in WorkDir::Base
# for making bundler available to subcommands from the main Rails environment
DOCKER_ENV_OPTS="-e GEM_PATH=/usr/local/bundle"

# This is probably only defined in specific CI environments, so only pass if available
GEMNASIUM_TOKEN=${GEMNASIUM_TOKEN:-}
if [ ! -z ${GEMNASIUM_TOKEN} ]; then
  DOCKER_ENV_OPTS=$DOCKER_ENV_OPTS" -e GEMNASIUM_TOKEN=$GEMNASIUM_TOKEN"
fi

docker-compose run $DOCKER_ENV_OPTS app bin/test_run.sh
