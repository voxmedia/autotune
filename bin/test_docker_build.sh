#!/bin/bash
set -euo pipefail

if [ -z ${SSH_KEY_PATH+x} ]; then
	export SSH_KEY_PATH=~/.ssh/id_rsa
else
	# For Jenkins, when you have to manually pass in a key
	chmod 700 $SSH_KEY_PATH
fi

docker-compose build
docker-compose run -e GEM_PATH=/usr/local/bundle:/root/.gem/ruby/2.2.0:/usr/local/lib/ruby/gems/2.2.0 app bin/test_run.sh
#docker-compose run app bin/test_run.sh
