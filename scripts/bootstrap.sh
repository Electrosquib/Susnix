#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_MODE=false

if [[ "${1:-}" == "--vm" ]]; then
    VM_MODE=true
fi

if [[ $EUID -eq 0 ]]; then
    TARGET_USER="${SUSNIX_USER:-}"

    if [[ -z "$TARGET_USER" ]]; then
        echo "SUSNIX_USER must be specified when running as root."
        exit 1
    fi

    PACMAN=(pacman)
    SYSTEMCTL=(systemctl)
else
    TARGET_USER="$USER"
    PACMAN=(sudo pacman)
    SYSTEMCTL=(sudo systemctl)
fi

HOME_DIR="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_GROUP="$(id -gn "$TARGET_USER")"

mapfile -t CORE_PKGS < <(grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/core.txt")
mapfile -t DESKTOP_PKGS < <(grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/desktop.txt")

"${PACMAN[@]}" -Syu --noconfirm
"${PACMAN[@]}" -S --needed --noconfirm "${CORE_PKGS[@]}"
"${PACMAN[@]}" -S --needed --noconfirm "${DESKTOP_PKGS[@]}"

"${SYSTEMCTL[@]}" enable NetworkManager

install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "$HOME_DIR/.config/hypr"
install -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$REPO_DIR/configs/hypr/hyprland.lua" \
    "$HOME_DIR/.config/hypr/hyprland.lua"

if [[ "$VM_MODE" == true ]]; then
    mapfile -t VM_PKGS < <(grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/vm.txt")

    "${PACMAN[@]}" -S --needed --noconfirm "${VM_PKGS[@]}"
    "${SYSTEMCTL[@]}" enable vboxservice
    "${SYSTEMCTL[@]}" enable sshd
fi

echo "Susnix desktop installation complete."
