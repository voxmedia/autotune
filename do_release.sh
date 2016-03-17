#!/bin/bash

if [ $# -ne 1 ]; then
    echo $0: usage: do_release.sh version
    exit 1
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "Missing jq. Please install jq."; exit 1; }
command -v sponge >/dev/null 2>&1 || { echo >&2 "Missing sponge. Please install moreutils."; exit 1; }

if git diff-index --quiet HEAD --; then
    # no changes
  jq ".version |= $1" package.json |sponge package.json
  git commit -am "bump to $1"
  git tag $1
  git push --tags
else
  echo You must commit all your changes before updating the version
    # changes
fi

