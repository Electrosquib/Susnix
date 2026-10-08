#!/usr/bin/env bash
set -euo pipefail
printf 'Home\t%s\n' "$HOME"
for location in Desktop Downloads Documents Pictures Music Videos; do
    location_path="$HOME/$location"
    if command -v xdg-user-dir >/dev/null; then
        location_path="$(xdg-user-dir "${location^^}")"
    fi
    [[ -d "$location_path" ]] || location_path="$HOME"
    printf '%s\t%s\n' "$location" "$location_path"
done
