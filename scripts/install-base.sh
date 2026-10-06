#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this as root from the Arch installation ISO."
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

DISK="$1"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -b "$DISK" ]]; then
    echo "$DISK is not a valid block device."
    exit 1
fi

echo
echo "WARNING: THIS WILL ERASE EVERYTHING ON:"
lsblk "$DISK"
echo

read -rp "Type ERASE to continue: " CONFIRM

if [[ "$CONFIRM" != "ERASE" ]]; then
    echo "Cancelled."
    exit 1
fi

if [[ "$DISK" =~ (nvme|mmcblk) ]]; then
    EFI="${DISK}p1"
    ROOT="${DISK}p2"
else
    EFI="${DISK}1"
    ROOT="${DISK}2"
fi

umount -R /mnt 2>/dev/null || true

wipefs -af "$DISK"

sfdisk "$DISK" <<EOF
label: gpt
size=1G, type=U
type=L
EOF

partprobe "$DISK"
sleep 2

mkfs.fat -F32 "$EFI"
mkfs.ext4 -F "$ROOT"

mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

pacstrap -K /mnt base linux linux-firmware sudo networkmanager nano git base-devel openssh

genfstab -U /mnt > /mnt/etc/fstab

mkdir -p /mnt/opt
cp -a "$REPO_DIR" /mnt/opt/susnix

echo
echo "Base Susnix installation complete."
echo
echo "EFI:  $EFI"
echo "Root: $ROOT"
echo
echo "Next:"
echo "arch-chroot /mnt"
echo "/opt/susnix/scripts/configure-system.sh"
