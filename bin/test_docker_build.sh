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
docker-compose run -e GEM_PATH=/usr/local/bundle app bin/test_run.sh
