#!/bin/sh

set -eu

if [ "$#" -gt 0 ]; then
	exec lms "$@"
fi

lms server start --bind 0.0.0.0
exec lms log stream --source server
