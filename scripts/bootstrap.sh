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

"${SYSTEMCTL[@]}" enable NetworkManager bluetooth

# Native terminal: use the distro Qt/QTermWidget packages, not bundled binaries.
bash "$REPO_DIR/scripts/setup-terminal.sh" "$TARGET_USER"
bash "$REPO_DIR/scripts/setup-launcher.sh" "$TARGET_USER"
bash "$REPO_DIR/scripts/setup-ask.sh" "$TARGET_USER"
bash "$REPO_DIR/scripts/setup-window-controls.sh" "$TARGET_USER"

# Standard personal folders, using the user's XDG paths when configured.
if [[ $EUID -eq 0 ]]; then
    runuser -u "$TARGET_USER" -- xdg-user-dirs-update
else
    xdg-user-dirs-update
fi

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
done < <(find "$REPO_DIR/configs/quickshell" -type f ! -name 'README.md' ! -path '*/__pycache__/*' -print0)

# Boot directly into the desktop; SUSNIX_AUTOLOGIN=false keeps password login.
desktop_start_args=("$TARGET_USER")
if [[ "${SUSNIX_AUTOLOGIN:-true}" == true ]]; then desktop_start_args+=(--autologin); fi
if [[ $EUID -eq 0 ]]; then
    bash "$REPO_DIR/scripts/setup-desktop-start.sh" "${desktop_start_args[@]}"
else
    sudo bash "$REPO_DIR/scripts/setup-desktop-start.sh" "${desktop_start_args[@]}"
fi

# User-session clipboard supervision needs no system-wide service or root at login.
install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$REPO_DIR/configs/virtualbox/clipboard.sh" "$HOME_DIR/.config/susnix/clipboard.sh"
install -D -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$REPO_DIR/configs/virtualbox/susnix-clipboard.service" \
    "$HOME_DIR/.config/systemd/user/susnix-clipboard.service"
# Enable offline too: no running user manager or display environment is needed.
install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "$HOME_DIR/.config/systemd/user/default.target.wants"
ln -sfn ../susnix-clipboard.service \
    "$HOME_DIR/.config/systemd/user/default.target.wants/susnix-clipboard.service"
chown -h "$TARGET_USER:$TARGET_GROUP" \
    "$HOME_DIR/.config/systemd/user/default.target.wants/susnix-clipboard.service"

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
