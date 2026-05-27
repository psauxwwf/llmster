#!/bin/sh

set -eu

wait_for_server() {
	_retries=30
	echo "Waiting for server to be ready..."
	while [ "$_retries" -gt 0 ]; do
		if curl -fsS http://127.0.0.1:1234/v1/models >/dev/null 2>&1; then
			echo "Server is ready"
			return 0
		fi
		sleep 1
		_retries=$((_retries - 1))
	done
	echo "Server did not become ready in 30s"
	return 1
}

LMS_INSTALL_LOC="/root/.lmstudio/.internal/llmster-install-location.json"
LMS_INSTALL_SRC="/root/llmster-install-location.json"

if [ ! -f "$LMS_INSTALL_LOC" ] && [ -f "$LMS_INSTALL_SRC" ]; then
	echo "Restoring install-location.json from $LMS_INSTALL_SRC"
	cp "$LMS_INSTALL_SRC" "$LMS_INSTALL_LOC"
fi

if [ "$#" -gt 0 ]; then
	echo "Executing: lms $*"
	exec lms "$@"
fi

echo "Starting LM Studio server on 0.0.0.0:1234"
lms server start --bind 0.0.0.0

if [ -n "${LMS_CONTEXT:-}" ]; then
	_settings="/root/.lmstudio/settings.json"
	if wait_for_server; then
		sleep 2
		if [ -f "$_settings" ]; then
			if [ "$LMS_CONTEXT" = "0" ]; then
				echo "Patching defaultContextLength: type=max"
				jq '.defaultContextLength.type = "max"' "$_settings" >"${_settings}.tmp" && mv "${_settings}.tmp" "$_settings"
			else
				echo "Patching defaultContextLength: type=custom, value=$LMS_CONTEXT"
				jq --arg v "$LMS_CONTEXT" '.defaultContextLength.type = "custom" | .defaultContextLength.value = ($v | tonumber)' "$_settings" >"${_settings}.tmp" && mv "${_settings}.tmp" "$_settings"
			fi
		else
			echo "settings.json not found, skipping context patch"
		fi
	fi
fi

echo "Streaming server logs"
exec lms log stream --source server &

if [ -n "${LMS_UPDATE:-}" ]; then
	lms runtime update --all
fi

if [ -n "${LMS_MUST_PULL:-}" ]; then
	if wait_for_server; then
		for _url in $LMS_MUST_PULL; do
			echo "Pulling model: $_url"
			lms get "$_url" --yes
		done
	fi
fi

wait
