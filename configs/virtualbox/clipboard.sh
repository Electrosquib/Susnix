#!/usr/bin/env bash
# Start a fresh clipboard bridge for each Hyprland login, with crash recovery.
set -euo pipefail
clipboard_unit=susnix-clipboard.service
clipboard_action="${1:-start}"
clipboard_script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/$(basename -- "${BASH_SOURCE[0]}")"
case "$clipboard_action" in
    status) exec systemctl --user status "$clipboard_unit" ;;
    logs) exec journalctl --user -u "$clipboard_unit" -n 40 --no-pager ;;
    stop) exec systemctl --user stop "$clipboard_unit" ;;
    start|restart|run|watch) ;;
    *) echo "Usage: bash $0 {start|restart|stop|status|logs}" >&2; exit 2 ;;
esac
# Harmless on physical machines, SSH sessions, or systems without Guest Additions.
if ! command -v VBoxClient >/dev/null; then exit 0; fi
if [[ ! -c /dev/vboxguest && "$(systemd-detect-virt --vm 2>/dev/null || true)" != oracle ]]; then exit 0; fi

# The installed service starts at login, before Hyprland supplies any display
# environment. Discover the compositor from its own lock file, not a stale
# systemd manager environment or a hardcoded wayland-0 socket.
if [[ "$clipboard_action" == watch ]]; then
    : "${XDG_RUNTIME_DIR:?The clipboard service needs a user runtime directory}"
    clipboard_child=""
    trap 'if [[ -n "$clipboard_child" ]]; then kill "$clipboard_child" 2>/dev/null || true; wait "$clipboard_child" 2>/dev/null || true; fi' EXIT
    trap 'exit 0' TERM INT
    echo 'Watching for an active Hyprland session.'
    while true; do
        for clipboard_lock in "$XDG_RUNTIME_DIR"/hypr/*/hyprland.lock; do
            [[ -f "$clipboard_lock" && -O "$clipboard_lock" ]] || continue
            clipboard_pid=""; clipboard_display=""
            { IFS= read -r clipboard_pid && IFS= read -r clipboard_display; } < "$clipboard_lock" || continue
            [[ "$clipboard_pid" =~ ^[0-9]+$ && "$clipboard_display" =~ ^wayland-[0-9]+$ ]] || continue
            [[ -O "/proc/$clipboard_pid" && -r "/proc/$clipboard_pid/comm" && -S "$XDG_RUNTIME_DIR/$clipboard_display" ]] || continue
            IFS= read -r clipboard_comm < "/proc/$clipboard_pid/comm" || continue
            [[ "$clipboard_comm" == Hyprland ]] || continue
            clipboard_signature="$(basename -- "$(dirname -- "$clipboard_lock")")"
            # Clean stale VirtualBox clipboard PID files before reconnecting.
            for clipboard_pid_file in "$HOME"/.vboxclient-clipboard*.pid; do
                [[ -f "$clipboard_pid_file" && -O "$clipboard_pid_file" ]] && rm -f -- "$clipboard_pid_file"
            done
            echo "Connecting clipboard to $clipboard_signature ($clipboard_display)."
            WAYLAND_DISPLAY="$clipboard_display" HYPRLAND_INSTANCE_SIGNATURE="$clipboard_signature" \
                XDG_SESSION_TYPE=wayland bash "$clipboard_script" run &
            clipboard_child=$!
            wait "$clipboard_child" || true
            clipboard_child=""
            break
        done
        sleep 2
    done
fi

# Prefer the enabled, persistent login service. The transient path below remains
# available for checkouts installed before the user unit was introduced.
if [[ "$clipboard_action" == start || "$clipboard_action" == restart ]] &&
    [[ "$(systemctl --user show "$clipboard_unit" -p FragmentPath --value 2>/dev/null || true)" == */systemd/user/susnix-clipboard.service ]]; then
    exec systemctl --user restart "$clipboard_unit"
fi
if [[ -z "${WAYLAND_DISPLAY:-}" || -z "${XDG_RUNTIME_DIR:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo 'Start clipboard sharing from the active Hyprland desktop.' >&2
    exit 1
fi
clipboard_session="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE"
if [[ "$clipboard_action" == run ]]; then
    # hyprland.start can fire before its lock file and Wayland socket are ready.
    # Queue supervision first, then wait here; a timeout is retried by systemd.
    echo 'Waiting for the Hyprland clipboard session to become ready.'
    clipboard_ready=false
    for ((attempt=0;attempt<300;attempt++)); do
        clipboard_compositor_pid=""
        if [[ -c /dev/vboxguest && -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" && -r "$clipboard_session/hyprland.lock" ]] &&
            IFS= read -r clipboard_compositor_pid < "$clipboard_session/hyprland.lock" &&
            [[ "$clipboard_compositor_pid" =~ ^[0-9]+$ ]] &&
            kill -0 "$clipboard_compositor_pid" 2>/dev/null; then
            clipboard_ready=true
            break
        fi
        sleep .1
    done
    if [[ "$clipboard_ready" != true ]]; then
        echo 'Hyprland clipboard session is not ready; systemd will retry.' >&2
        exit 1
    fi
    # Foreground mode allows systemd to supervise the actual bridge.
    VBoxClient --clipboard --session-type wayland --foreground --verbose &
    clipboard_client_pid=$!
    cleanup() {
        kill "$clipboard_client_pid" 2>/dev/null || true
        wait "$clipboard_client_pid" 2>/dev/null || true
    }
    trap cleanup EXIT
    trap 'exit 0' TERM INT
    while kill -0 "$clipboard_client_pid" 2>/dev/null; do
        # VBoxClient can survive a compositor restart while holding a dead connection.
        # End with success when this particular desktop exits, preventing restart loops.
        if ! kill -0 "$clipboard_compositor_pid" 2>/dev/null; then exit 0; fi
        sleep 3
    done
    wait "$clipboard_client_pid" 2>/dev/null || true
    echo 'Clipboard bridge exited; restarting in the current desktop session.' >&2
    exit 1
fi

clipboard_runtime="$XDG_RUNTIME_DIR/susnix"
mkdir -p -m 0700 "$clipboard_runtime"
exec 9>"$clipboard_runtime/clipboard.lock"
flock 9
# Stop supervision first, then remove only this user's legacy clipboard clients.
systemctl --user stop "$clipboard_unit" 2>/dev/null || true
clipboard_pids=()
while IFS= read -r clipboard_pid; do
    [[ -r "/proc/$clipboard_pid/cmdline" ]] || continue
    mapfile -d '' -t clipboard_args < "/proc/$clipboard_pid/cmdline" || continue
    for clipboard_arg in "${clipboard_args[@]}"; do
        if [[ "$clipboard_arg" == --clipboard ]]; then
            clipboard_pids+=("$clipboard_pid")
            kill "$clipboard_pid" 2>/dev/null || true
            break
        fi
    done
done < <(pgrep -u "$UID" -x VBoxClient || true)
for ((attempt=0;attempt<30;attempt++)); do
    clipboard_alive=false
    for clipboard_pid in "${clipboard_pids[@]}"; do
        if kill -0 "$clipboard_pid" 2>/dev/null; then clipboard_alive=true; fi
    done
    [[ "$clipboard_alive" == false ]] && break
    sleep .1
done
if [[ "$clipboard_alive" == true ]]; then
    echo 'Old clipboard client did not stop; inspect clipboard logs.' >&2
    exit 1
fi
# PID files may contain old service/session locks, never other VBoxClient services.
for clipboard_pid_file in "$HOME"/.vboxclient-clipboard*.pid; do
    [[ -f "$clipboard_pid_file" && -O "$clipboard_pid_file" ]] && rm -f -- "$clipboard_pid_file"
done
clipboard_env=(--setenv="WAYLAND_DISPLAY=$WAYLAND_DISPLAY" --setenv="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
    --setenv="HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE" --setenv=XDG_SESSION_TYPE=wayland
    --setenv="PATH=$PATH")
if [[ -n "${DISPLAY:-}" ]]; then clipboard_env+=(--setenv="DISPLAY=$DISPLAY"); fi
systemd-run --user --quiet --collect --unit="$clipboard_unit" \
    --description='Susnix VirtualBox clipboard sharing' \
    --property=Restart=on-failure --property=RestartSec=2s \
    --property=StartLimitIntervalSec=0 --property=TimeoutStopSec=5s \
    "${clipboard_env[@]}" /usr/bin/bash "$clipboard_script" run 9>&-
echo 'Clipboard sharing started for this desktop, with automatic recovery.'
