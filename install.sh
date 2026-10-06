#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this installer as root from the Arch Linux ISO."
    exit 1
fi

if [[ ! -d /sys/firmware/efi/efivars ]]; then
    echo "System was not booted using UEFI."
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DISK="${1:-}"

if [[ -z "$DISK" ]]; then
    lsblk
    echo
    read -rp "Target disk: " DISK
fi

read -rp "Hostname [susnix]: " HOSTNAME
HOSTNAME="${HOSTNAME:-susnix}"

read -rp "Username: " USERNAME

while [[ -z "$USERNAME" ]]; do
    read -rp "Username cannot be empty: " USERNAME
done

read -rp "Timezone [UTC]: " TIMEZONE
TIMEZONE="${TIMEZONE:-UTC}"

echo
echo "Susnix installation"
echo "-------------------"
echo "Disk:     $DISK"
echo "Hostname: $HOSTNAME"
echo "Username: $USERNAME"
echo "Timezone: $TIMEZONE"
echo

read -rp "Continue? [y/N]: " CONFIRM

if [[ "${CONFIRM,,}" != "y" ]]; then
    echo "Cancelled."
    exit 0
fi

"$REPO_DIR/scripts/install-base.sh" "$DISK"

arch-chroot /mnt env \
    SUSNIX_HOSTNAME="$HOSTNAME" \
    SUSNIX_USERNAME="$USERNAME" \
    SUSNIX_TIMEZONE="$TIMEZONE" \
    /opt/susnix/scripts/configure-system.sh

arch-chroot /mnt env \
    SUSNIX_USER="$USERNAME" \
    /opt/susnix/scripts/bootstrap.sh --vm

echo
echo "================================="
echo "Susnix installation complete."
echo "================================="
echo
echo "Run:"
echo
echo "umount -R /mnt"
echo "reboot"
