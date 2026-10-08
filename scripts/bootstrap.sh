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

# Keep the existing copy-based config installation model.
install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$HOME_DIR/.config/quickshell/susnix"
while IFS= read -r -d '' config_file; do
    relative_path="${config_file#"$REPO_DIR/configs/quickshell/"}"
    install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
        "$config_file" "$HOME_DIR/.config/quickshell/susnix/$relative_path"
done < <(find "$REPO_DIR/configs/quickshell" -type f ! -name 'README.md' -print0)

# Boot directly into the desktop; SUSNIX_AUTOLOGIN=false keeps password login.
desktop_start_args=("$TARGET_USER")
if [[ "${SUSNIX_AUTOLOGIN:-true}" == true ]]; then desktop_start_args+=(--autologin); fi
if [[ $EUID -eq 0 ]]; then
    bash "$REPO_DIR/scripts/setup-desktop-start.sh" "${desktop_start_args[@]}"
else
    sudo bash "$REPO_DIR/scripts/setup-desktop-start.sh" "${desktop_start_args[@]}"
fi

if [[ "$VM_MODE" == true ]]; then
    mapfile -t VM_PKGS < <(grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/vm.txt")

    "${PACMAN[@]}" -S --needed --noconfirm "${VM_PKGS[@]}"
    if [[ $EUID -eq 0 ]]; then
        bash "$REPO_DIR/scripts/setup-vm-display.sh" --install-only
    else
        sudo bash "$REPO_DIR/scripts/setup-vm-display.sh" --install-only
    fi
    "${SYSTEMCTL[@]}" enable sshd
fi

echo "Susnix desktop installation complete."
