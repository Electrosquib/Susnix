#!/usr/bin/env bash
set -euo pipefail
controls_plugin="$HOME/.local/lib/susnix-window-controls.so"
controls_hash="$HOME/.local/lib/susnix-window-controls.hash"
[[ -r "$controls_plugin" && -r "$controls_hash" ]] || exit 0
controls_running_hash="$(hyprctl -j version | python -c 'import json,sys;print(json.load(sys.stdin)["commit"])')"
if [[ "$controls_running_hash" != "$(cat "$controls_hash")" ]]; then
    echo 'Window controls need rebuilding for the updated Hyprland. Run scripts/setup-window-controls.sh.' >&2
    exit 0
fi
if ! hyprctl -j plugin list | python -c 'import json,sys;sys.exit(0 if any(p.get("name")=="hyprbars" for p in json.load(sys.stdin)) else 1)'; then
    hyprctl plugin load "$controls_plugin"
fi
