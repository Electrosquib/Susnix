#!/usr/bin/env bash
# Install the Susnix shell and its bundled desktop assets as the desktop user.
set -euo pipefail
if [[ $EUID -eq 0 ]]; then
    echo 'Run this script as the desktop user, without sudo.' >&2
    exit 1
fi
desktop_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
desktop_config="${XDG_CONFIG_HOME:-$HOME/.config}"
while IFS= read -r -d '' desktop_file; do
    desktop_relative="${desktop_file#"$desktop_repo/configs/quickshell/"}"
    install -D -m 0644 "$desktop_file" "$desktop_config/quickshell/susnix/$desktop_relative"
done < <(find "$desktop_repo/configs/quickshell" -type f ! -name README.md ! -path "*/__pycache__/*" -print0)
if command -v xdg-user-dirs-update >/dev/null; then
    xdg-user-dirs-update
else
    mkdir -p "$HOME"/{Desktop,Downloads,Documents,Pictures,Music,Videos}
fi
mkdir -p "$HOME"/Projects "$HOME"/Radar "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files" "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/info"
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    bash "$desktop_config/quickshell/susnix/bar.sh" restart
else
    echo 'Susnix desktop installed; it will load with the existing Hyprland autostart.'
fi
