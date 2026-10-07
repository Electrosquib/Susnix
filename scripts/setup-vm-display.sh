#!/usr/bin/env bash
# Enable the already-installed VirtualBox Guest Additions resize bridge.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
if [[ $EUID -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi
if [[ ! -x /usr/bin/VBoxDRMClient ]]; then
    echo 'Install virtualbox-guest-utils first.' >&2
    exit 1
fi
# Prefer a distribution-provided bridge if available; do not run two daemons.
if systemctl cat vboxdrmclient.service >/dev/null 2>&1; then
    resize_unit=vboxdrmclient.service
else
    resize_unit=susnix-vm-resize.service
    install -m 0644 "$repo_dir/configs/virtualbox/$resize_unit" "/etc/systemd/system/$resize_unit"
    systemctl daemon-reload
fi
if [[ "${1:-}" == --install-only ]]; then
    systemctl enable vboxservice.service "$resize_unit"
else
    systemctl enable --now vboxservice.service "$resize_unit"
fi
