#!/bin/sh

set -eu

lmstudio_home="${HOME:-/root}/.lmstudio"
install_root="$lmstudio_home/llmster"
internal_dir="$lmstudio_home/.internal"
install_meta="$internal_dir/llmster-install-location.json"

ensure_install_metadata() {
	mkdir -p "$internal_dir"

	set -- "$install_root"/*/llmster
	install_bin="$1"

	if [ ! -e "$install_bin" ]; then
		printf '%s\n' "llmster install binary was not found under $install_root" >&2
		exit 1
	fi

	if [ -f "$install_meta" ]; then
		return
	fi

	install_dir=${install_bin%/*}
	printf '{\n  "path": "%s",\n  "argv": [],\n  "cwd": "%s"\n}\n' \
		"$install_bin" \
		"$install_dir" >"$install_meta"
}

ensure_install_metadata

if [ "$#" -gt 0 ]; then
	exec lms "$@"
fi

lms server start --bind 0.0.0.0
exec lms log stream --source server
