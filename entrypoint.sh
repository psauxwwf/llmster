#!/bin/sh

set -eu

SERVER_URL="http://127.0.0.1:1234/v1/models"
SETTINGS_FILE="/root/.lmstudio/settings.json"
INSTALL_LOCATION_FILE="/root/.lmstudio/.internal/llmster-install-location.json"
INSTALL_LOCATION_SOURCE="/root/llmster-install-location.json"
RUNTIME_NO_CHANGES_MSG="All matching runtime extensions are already up-to-date."

wait_for_server() {
	retries=30
	echo "Waiting for server to be ready..."
	while [ "$retries" -gt 0 ]; do
		if curl -fsS "$SERVER_URL" >/dev/null 2>&1; then
			echo "Server is ready"
			return 0
		fi
		sleep 1
		retries=$((retries - 1))
	done
	echo "Server did not become ready in 30s"
	return 1
}

is_enabled() {
	value=${1:-}
	case "$value" in
	true | yes | 1) return 0 ;;
	*) return 1 ;;
	esac
}

has_models_to_pull() {
	value=${1:-}
	case "$value" in
	"" | '""') return 1 ;;
	*) return 0 ;;
	esac
}

patch_context() {
	context_value=$1
	tmp_file="${SETTINGS_FILE}.tmp"

	if [ ! -f "$SETTINGS_FILE" ]; then
		echo "settings.json not found, skipping context patch"
		return 0
	fi

	if [ "$context_value" = "0" ]; then
		echo "Patching defaultContextLength: type=max"
		jq '.defaultContextLength.type = "max"' "$SETTINGS_FILE" >"$tmp_file"
		mv "$tmp_file" "$SETTINGS_FILE"
		return 0
	fi

	echo "Patching defaultContextLength: type=custom, value=$context_value"
	jq --arg v "$context_value" '.defaultContextLength.type = "custom" | .defaultContextLength.value = ($v | tonumber)' "$SETTINGS_FILE" >"$tmp_file"
	mv "$tmp_file" "$SETTINGS_FILE"
}

update_runtimes() {
	for attempt in 1 2 3; do
		echo "Refreshing runtime catalog..."
		lms runtime get --list --allow-incompatible >/dev/null 2>&1 || true
		sleep 2

		echo "Checking updates for installed runtimes..."
		if output=$(lms runtime update --all --yes --allow-incompatible 2>&1); then
			printf '%s\n' "$output"
			case "$output" in
			*"$RUNTIME_NO_CHANGES_MSG"*)
				if [ "$attempt" -lt 3 ]; then
					echo "Runtime update returned no changes, retrying..."
					sleep 5
					continue
				fi
				;;
			esac
			return 0
		fi
		printf '%s\n' "$output"
		return 1
	done

	return 0
}

pull_models() {
	model_urls=$1
	previous_ifs=$IFS
	IFS=';'
	for url in $model_urls; do
		[ -z "$url" ] && continue
		for attempt in 1 2 3; do
			echo "Pulling model: $url"
			if lms get "$url" --yes; then
				break
			fi
			if [ "$attempt" -lt 3 ]; then
				echo "Model pull failed, retrying..."
				sleep 5
				continue
			fi
			IFS=$previous_ifs
			return 1
		done
	done
	IFS=$previous_ifs
}

if [ ! -f "$INSTALL_LOCATION_FILE" ] && [ -f "$INSTALL_LOCATION_SOURCE" ]; then
	echo "Restoring install-location.json from $INSTALL_LOCATION_SOURCE"
	cp "$INSTALL_LOCATION_SOURCE" "$INSTALL_LOCATION_FILE"
fi

if [ "$#" -gt 0 ]; then
	echo "Executing: lms $*"
	exec lms "$@"
fi

echo "Starting LM Studio server on 0.0.0.0:1234"
lms server start --bind 0.0.0.0

wait_for_server
sleep 2

if [ -n "${LMS_CONTEXT:-}" ]; then
	patch_context "$LMS_CONTEXT"
fi

echo "Streaming server logs"
lms log stream --source server &

if is_enabled "${LMS_UPDATE:-}"; then
	update_runtimes
else
	echo "LMS_UPDATE is empty, skipping runtime update"
fi

if has_models_to_pull "${LMS_MUST_PULL:-}"; then
	pull_models "$LMS_MUST_PULL"
else
	echo "LMS_MUST_PULL is empty, skipping model pull"
fi

wait
