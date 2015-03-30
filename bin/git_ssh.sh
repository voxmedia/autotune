#!/bin/sh
exec ssh -i "$GIT_PRIVATE_KEY" -o "StrictHostKeyChecking no" "$@"
