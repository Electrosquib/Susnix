#!/usr/bin/env bash
set -euo pipefail
desktop_terminal_config="${XDG_CONFIG_HOME:-$HOME/.config}/susnix/foot.ini"
if [[ -r "$desktop_terminal_config" ]]; then
    exec foot --config "$desktop_terminal_config" "$@"
fi
exec foot "$@"
