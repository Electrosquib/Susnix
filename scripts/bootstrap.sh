#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root."
    exit 1
fi

sudo pacman -Syu --noconfirm

sudo pacman -S --needed --noconfirm $(grep -v '^#' "$REPO_DIR/packages/core.txt")
sudo pacman -S --needed --noconfirm $(grep -v '^#' "$REPO_DIR/packages/desktop.txt")

sudo systemctl enable NetworkManager
sudo systemctl enable sshd

mkdir -p "$HOME/.config/hypr"
cp "$REPO_DIR/configs/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"

if [[ "${1:-}" == "--vm" ]]; then
    sudo pacman -S --needed --noconfirm $(grep -v '^#' "$REPO_DIR/packages/vm.txt")
    sudo systemctl enable vboxservice
fi

echo "Susnix base installation complete."
echo "Reboot, log in, then run: Hyprland"
