#!/usr/bin/env bash
# Configure tty1 desktop startup without restarting the current login/session.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
target_user="${1:-${SUSNIX_USER:-${SUDO_USER:-${USER:-}}}}"
autologin=false
if [[ "${2:-}" == --autologin ]]; then autologin=true; fi
if [[ $# -gt 2 || ( $# -eq 2 && "$2" != --autologin ) ]]; then
    echo "Usage: bash $0 USER [--autologin]" >&2
    exit 2
fi
if [[ $EUID -ne 0 ]]; then
    if [[ "$autologin" == true ]]; then exec sudo bash "$0" "$target_user" --autologin; fi
    exec sudo bash "$0" "$target_user"
fi
if [[ ! "$target_user" =~ ^[a-z_][a-z0-9_-]*[$]?$ || "$(id -u "$target_user")" == 0 ]]; then
    echo 'Specify an existing non-root desktop user.' >&2
    exit 1
fi
account="$(getent passwd "$target_user")"
IFS=: read -r _ _ _ _ _ desktop_home desktop_shell <<< "$account"
if [[ "$desktop_shell" != /bin/bash && "$desktop_shell" != /usr/bin/bash ]]; then
    echo 'Automatic desktop startup currently supports Bash login shells.' >&2
    exit 1
fi
desktop_group="$(id -gn "$target_user")"
if [[ "$autologin" == true && -e /etc/systemd/system/display-manager.service ]]; then
    echo 'An existing display manager is configured; leaving its login policy unchanged.' >&2
    exit 1
fi
install -D -m 0644 -o "$target_user" -g "$desktop_group" \
    "$repo_dir/configs/session/start-hyprland.sh" "$desktop_home/.config/susnix/start-hyprland.sh"
profile="$desktop_home/.bash_profile"
if [[ ! -e "$profile" ]]; then
    install -m 0644 -o "$target_user" -g "$desktop_group" /dev/null "$profile"
    printf '%s\n' '[[ -f ~/.bashrc ]] && . ~/.bashrc' >> "$profile"
fi
profile_line='[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/susnix/start-hyprland.sh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/susnix/start-hyprland.sh"'
if ! grep -Fqx "$profile_line" "$profile"; then
    cp -p -- "$profile" "$profile.susnix-before-desktop-start"
    printf '\n# Susnix: launch the desktop on tty1 login.\n%s\n' "$profile_line" >> "$profile"
fi
if [[ "$autologin" == true ]]; then
    install -d -m 0755 /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/susnix-autologin.conf <<UNIT
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $target_user --noreset --noclear - \${TERM}
UNIT
    if [[ -d /run/systemd/system ]]; then systemctl daemon-reload; fi
fi
# Enable for the next boot; do not stop or restart the active tty/Hyprland.
systemctl enable getty@tty1.service
printf 'Hyprland startup configured for %s on tty1 (automatic login: %s).\n' "$target_user" "$autologin"
