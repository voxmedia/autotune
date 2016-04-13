#!/bin/bash
set -euo pipefail

if [ -z ${PROJECT_NAME+x} ]; then
	PROJECT_NAME=${PWD##*/}
fi
IMAGE_TAG=$PROJECT_NAME:latest

if [ -z ${SSH_KEY_PATH+x} ]; then
	SSH_KEY_PATH=~/.ssh/id_rsa
else
	# For Jenkins, when you have to manually pass in a key
	chmod 700 $SSH_KEY_PATH
fi

function cleanup {
	(docker stop $PROJECT_NAME\_redis && docker rm $PROJECT_NAME\_redis) || true
}
trap cleanup EXIT 

docker run \
	--detach \
	--name $PROJECT_NAME\_redis \
	redis:3.0

docker build \
	--tag=$IMAGE_TAG \
	.

docker run \
	--link $PROJECT_NAME\_redis \
	--volume "$SSH_KEY_PATH":/root/.ssh/id_rsa \
	--volume $(pwd):/app \
	$IMAGE_TAG
