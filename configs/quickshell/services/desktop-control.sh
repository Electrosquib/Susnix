#!/usr/bin/env bash
# All inputs remain separate argv values. No eval or user-controlled shell commands.
set -euo pipefail
export LC_ALL=C
case "${1:-}" in
    snapshot)
        printf 'lock=%s\n' "$(command -v hyprlock >/dev/null && echo 1 || echo 0)"
        printf 'pairing=%s\n' "$(command -v blueman-manager >/dev/null && echo 1 || echo 0)"
        printf 'bluetooth=%s\n' "$(systemctl is-active --quiet bluetooth.service && echo 1 || echo 0)"
        value=-1
        if command -v brightnessctl >/dev/null; then
            current=$(timeout 2s brightnessctl --class=backlight get 2>/dev/null || true)
            maximum=$(timeout 2s brightnessctl --class=backlight max 2>/dev/null || true)
            if [[ "$current" =~ ^[0-9]+$ && "$maximum" =~ ^[0-9]+$ ]] && ((maximum>0)); then value=$((100*current/maximum)); fi
        fi
        printf 'brightness=%s\n' "$value"
        ;;
    brightness)
        [[ "${2:-}" =~ ^[0-9]+$ ]] && ((10#$2>=1 && 10#$2<=100)) || { echo 'Brightness must be between 1 and 100 percent.' >&2; exit 2; }
        timeout 3s brightnessctl --class=backlight set "$2%"
        ;;
    bluetooth)
        [[ "${2:-}" =~ ^/org/bluez/hci[0-9]+/dev_[0-9A-Fa-f_]+$ ]] || exit 2
        [[ "${3:-}" == Connect || "${3:-}" == Disconnect ]] || exit 2
        busctl --system --timeout=15 call org.bluez "$2" org.bluez.Device1 "$3"
        ;;
    pairing)
        command -v blueman-manager >/dev/null || { echo 'Install blueman to pair Bluetooth devices.' >&2; exit 1; }
        blueman-manager >/dev/null 2>&1 &
        ;;
    lock)
        command -v hyprlock >/dev/null || { echo 'Install hyprlock to enable screen locking.' >&2; exit 1; }
        for color in "${2:-}" "${3:-}" "${4:-}"; do
            [[ "$color" =~ ^#[0-9a-fA-F]{6}$ ]] || exit 2
        done
        umask 077
        lock_dir="${XDG_RUNTIME_DIR:?}/susnix"
        mkdir -p "$lock_dir"
        lock_file=$(mktemp "$lock_dir/lock.XXXXXX.conf")
        trap 'rm -f "$lock_file"' EXIT
        cat > "$lock_file" <<CONFIG
background {
    monitor =
    color = rgb(${2#\#})
}
input-field {
    monitor =
    size = 280, 54
    position = 0, -60
    halign = center
    valign = center
    outer_color = rgb(${4#\#})
    inner_color = rgb(${2#\#})
    font_color = rgb(${3#\#})
    placeholder_text = Unlock Susnix
    rounding = 4
    outline_thickness = 2
}
CONFIG
        hyprlock --config "$lock_file"
        ;;
    logout) hyprctl dispatch exit ;;
    reboot) systemctl reboot ;;
    poweroff) systemctl poweroff ;;
    *) echo 'Unknown desktop action.' >&2; exit 2 ;;
esac
