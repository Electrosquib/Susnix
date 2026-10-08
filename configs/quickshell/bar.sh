#!/usr/bin/env bash
# One Susnix bar across installed/checkout paths; leave other shells alone.
set -euo pipefail

bar_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
bar_unit="susnix-bar.service"
bar_action="${1:-reload}"

case "$bar_action" in
    start|reload|restart|stop|status|logs|control|files|applications|appearance) ;;
    *) echo "Usage: bash $0 {start|reload|restart|stop|status|logs|control|files|applications|appearance}" >&2; exit 2 ;;
esac

if [[ "$bar_action" == status ]]; then
    exec systemctl --user status "$bar_unit"
elif [[ "$bar_action" == logs ]]; then
    exec journalctl --user -u "$bar_unit" -n 60 --no-pager
fi

bar_qs="$(command -v quickshell)" || { echo 'Quickshell is not installed.' >&2; exit 1; }

if [[ -z "${XDG_RUNTIME_DIR:-}" || ( "$bar_action" != stop && -z "${WAYLAND_DISPLAY:-}" ) ]]; then
    echo 'Run this command in a terminal inside your active Hyprland desktop.' >&2
    exit 1
fi
if ! systemctl --user show-environment >/dev/null 2>&1; then
    echo 'Cannot connect to the systemd user manager. Run inside your desktop session.' >&2
    exit 1
fi

# Serialize autostart and manual launches across both configuration paths.
bar_runtime="$XDG_RUNTIME_DIR/susnix"
mkdir -p -m 0700 "$bar_runtime"
exec 9>"$bar_runtime/bar.lock"
flock 9
bar_previous=""
if [[ -f "$bar_runtime/bar-config" ]]; then
    IFS= read -r bar_previous < "$bar_runtime/bar-config" || true
fi
# Quickshell can return status 0 for an unavailable IPC handler during reload.
bar_ipc() {
    local bar_reply
    bar_reply="$("$bar_qs" ipc -p "$1" call bar "$2" 2>&1)" || return 1
    case "$bar_reply" in
        *'Not ready to accept queries yet.'*|*'Function not found.'*|*'No running instances'*|*'Target not found.'*) return 1 ;;
    esac
    [[ -z "$bar_reply" ]] || printf '%s\n' "$bar_reply"
    return 0
}
bar_ready() {
    local bar_theme
    bar_theme="$(bar_ipc "$1" currentTheme)" || return 1
    case "$bar_theme" in Nyx|Aurora|Void|Sakura|Terminal|Ember) return 0;; *) return 1;; esac
}
bar_wait_ready() {
    for ((bar_retry=0;bar_retry<20;bar_retry++)); do
        if bar_ready "$1"; then return 0; fi
        sleep 0.1
    done
    return 1
}
bar_toggle_after_start=false
bar_ipc_action="$bar_action"
if [[ "$bar_action" == control || "$bar_action" == files || "$bar_action" == applications || "$bar_action" == appearance ]]; then
    [[ "$bar_action" == control ]] && bar_ipc_action=toggleControl
    [[ "$bar_action" == appearance ]] && bar_ipc_action=refreshAppearance
    # Target the active checkout/installed instance instead of starting another bar.
    if [[ -n "$bar_previous" && -f "$bar_previous/services/TaskService.qml" ]] &&
        bar_wait_ready "$bar_previous" && bar_ipc "$bar_previous" "$bar_ipc_action" >/dev/null 2>&1; then
        exit 0
    fi
    bar_toggle_after_start=true
    bar_action=restart
fi
bar_dirs=("$bar_dir" "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/susnix" "$HOME/susnix/configs/quickshell")
if [[ -n "$bar_previous" ]]; then bar_dirs+=("$bar_previous"); fi

# Stop recovery before removing old instances. Only recognize Susnix configs.
if [[ "$bar_action" == stop || "$bar_action" == restart || ( -n "$bar_previous" && "$bar_previous" != "$bar_dir" ) ]]; then
    systemctl --user stop "$bar_unit" 2>/dev/null || true
fi
for candidate in "${bar_dirs[@]}"; do
    if [[ ! -f "$candidate/services/TaskService.qml" || ! -f "$candidate/theme/ThemeManager.qml" ]]; then continue; fi
    candidate="$(cd -- "$candidate" && pwd -P)"
    legacy_hash="$(printf '%s' "$candidate" | sha256sum)"
    legacy_unit="susnix-bar-${legacy_hash:0:12}.service"
    legacy_state="$(systemctl --user show "$legacy_unit" -p ActiveState --value 2>/dev/null || true)"
    systemctl --user stop "$legacy_unit" 2>/dev/null || true
    if [[ "$candidate" != "$bar_dir" || "$bar_action" == restart || "$bar_action" == stop || "$legacy_state" == active || "$legacy_state" == activating ]]; then
        "$bar_qs" kill -p "$candidate" >/dev/null 2>&1 || true
    fi
done
if [[ "$bar_action" == stop ]]; then
    rm -f "$bar_runtime/bar-config"
    exit 0
fi

bar_state="$(systemctl --user show "$bar_unit" -p ActiveState --value 2>/dev/null || true)"
if [[ "$bar_state" == active || "$bar_state" == activating ]]; then
    if [[ "$bar_action" == reload ]] && bar_ipc "$bar_dir" reload >/dev/null 2>&1; then
        echo 'Susnix bar reloaded.'
        exit 0
    fi
else
    # Adopt a terminal-launched instance into supervision, without touching other configs.
    if bar_ready "$bar_dir" >/dev/null 2>&1; then
        "$bar_qs" kill -p "$bar_dir" >/dev/null
        for ((attempt = 0; attempt < 20; attempt++)); do
            if ! bar_ready "$bar_dir" >/dev/null 2>&1; then break; fi
            sleep 0.1
        done
    fi
    bar_env=(--setenv="WAYLAND_DISPLAY=$WAYLAND_DISPLAY" --setenv="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
        --setenv="PATH=$PATH" --setenv=QT_QPA_PLATFORM=wayland
        --setenv="QT_QUICK_BACKEND=${QT_QUICK_BACKEND:-software}")
    for variable in DISPLAY XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE; do
        if [[ -n "${!variable:-}" ]]; then bar_env+=(--setenv="$variable=${!variable}"); fi
    done
    # Remember arbitrary checkout locations for the next installed launch.
    (umask 077; printf '%s\n' "$bar_dir" > "$bar_runtime/bar-config.tmp")
    mv "$bar_runtime/bar-config.tmp" "$bar_runtime/bar-config"
    systemd-run --user --quiet --collect --unit="$bar_unit" \
        --description='Susnix desktop bar' --property=Restart=always --property=RestartSec=2s \
        --property=StartLimitIntervalSec=30s --property=StartLimitBurst=5 \
        --property=TimeoutStopSec=5s "${bar_env[@]}" \
        "$bar_qs" -p "$bar_dir" --no-duplicate --no-color 9>&-
fi

# A queued service is not proof that the QML loaded: wait for its IPC handler.
for ((attempt = 0; attempt < 50; attempt++)); do
    if bar_ready "$bar_dir" >/dev/null 2>&1; then
        if [[ "$bar_toggle_after_start" == true ]]; then
            bar_ipc "$bar_dir" "$bar_ipc_action"
        fi
        echo 'Susnix bar is running with automatic recovery.'
        exit 0
    fi
    sleep 0.2
done
printf 'Susnix bar did not become ready. Inspect its log:\nbash %q logs\n' "$bar_dir/bar.sh" >&2
exit 1
