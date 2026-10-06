#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root inside arch-chroot."
    exit 1
fi

HOSTNAME="${SUSNIX_HOSTNAME:-}"
USERNAME="${SUSNIX_USERNAME:-}"
TIMEZONE="${SUSNIX_TIMEZONE:-}"

if [[ -z "$HOSTNAME" ]]; then
    read -rp "Hostname [susnix]: " HOSTNAME
    HOSTNAME="${HOSTNAME:-susnix}"
fi

if [[ -z "$USERNAME" ]]; then
    read -rp "Username: " USERNAME
    while [[ -z "$USERNAME" ]]; do
        read -rp "Username cannot be empty: " USERNAME
    done
fi

if [[ -z "$TIMEZONE" ]]; then
    read -rp "Timezone [UTC]: " TIMEZONE
    TIMEZONE="${TIMEZONE:-UTC}"
fi





LOCALE="en_US.UTF-8"

echo
echo "Hostname: $HOSTNAME"
echo "Username: $USERNAME"
echo "Timezone: $TIMEZONE"
echo "Locale:   $LOCALE"
echo

read -rp "Continue? [Y/n]: " CONFIRM
if [[ "${CONFIRM,,}" == "n" ]]; then
    exit 0
fi

if [[ ! -e "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    echo "Invalid timezone: $TIMEZONE"
    exit 1
fi

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname

cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF

if ! id "$USERNAME" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash "$USERNAME"
fi

echo "Set password for $USERNAME:"
passwd "$USERNAME"

install -d -m 0750 /etc/sudoers.d
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -cf /etc/sudoers.d/10-wheel

systemctl enable NetworkManager

ROOT_DEVICE="$(findmnt -n -o SOURCE /)"
ROOT_UUID="$(blkid -s UUID -o value "$ROOT_DEVICE")"

if [[ -z "$ROOT_UUID" ]]; then
    echo "Could not determine root filesystem UUID."
    exit 1
fi

bootctl install

mkdir -p /boot/loader/entries

cat > /boot/loader/loader.conf <<EOF
default susnix.conf
timeout 3
console-mode max
editor no
EOF

cat > /boot/loader/entries/susnix.conf <<EOF
title Susnix
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
EOF

mkinitcpio -P

echo
echo "Susnix system configuration complete."
echo "User: $USERNAME"
echo "Hostname: $HOSTNAME"
echo "Root UUID: $ROOT_UUID"
echo
echo "Exit arch-chroot, unmount /mnt, then reboot."
