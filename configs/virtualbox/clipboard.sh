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
    start|restart|run) ;;
    *) echo "Usage: bash $0 {start|restart|stop|status|logs}" >&2; exit 2 ;;
esac
# Harmless on physical machines, SSH sessions, or systems without Guest Additions.
if [[ ! -c /dev/vboxguest ]] || ! command -v VBoxClient >/dev/null; then exit 0; fi
if [[ -z "${WAYLAND_DISPLAY:-}" || -z "${XDG_RUNTIME_DIR:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo 'Start clipboard sharing from the active Hyprland desktop.' >&2
    exit 1
fi
clipboard_session="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE"
if [[ ! -r "$clipboard_session/hyprland.lock" ]]; then exit 0; fi
IFS= read -r clipboard_compositor_pid < "$clipboard_session/hyprland.lock"
[[ "$clipboard_compositor_pid" =~ ^[0-9]+$ ]] || exit 1

if [[ "$clipboard_action" == run ]]; then
    kill -0 "$clipboard_compositor_pid" 2>/dev/null || exit 0
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
