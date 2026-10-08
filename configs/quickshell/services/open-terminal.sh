#!/usr/bin/env bash
set -euo pipefail
# Keep Foot as a fallback for installations that have not built Susnix Term yet.
if [[ -x "$HOME/.local/bin/susnix-terminal" ]]; then
    # A plain launcher click restores a minimized terminal before creating another.
    if [[ $# -eq 0 && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        terminal_minimized="$(hyprctl -j clients 2>/dev/null | python -c 'import json,sys; clients=json.load(sys.stdin); print(next((c["pid"] for c in clients if c["class"]=="susnix-terminal" and c["workspace"]["name"]=="special:susnix-minimized"),""))' 2>/dev/null || true)"
        if [[ "$terminal_minimized" =~ ^[0-9]+$ ]]; then
            hyprctl eval "hl.dispatch(hl.dsp.window.move({window=\"pid:$terminal_minimized\",workspace=hl.get_active_workspace(),follow=false})); hl.dispatch(hl.dsp.focus({window=\"pid:$terminal_minimized\"}))" >/dev/null
            exit 0
        fi
    fi
    terminal_args=()
    [[ "${1:-}" == -e ]] && shift
    # Existing launchers pass Foot's -e for Terminal=true entries.
    [[ $# -gt 0 ]] && terminal_args=(-- "$@")
    exec "$HOME/.local/bin/susnix-terminal" --working-directory "$PWD" "${terminal_args[@]}"
fi
desktop_terminal_config="${XDG_CONFIG_HOME:-$HOME/.config}/susnix/foot.ini"
if [[ -r "$desktop_terminal_config" ]]; then
    exec foot --config "$desktop_terminal_config" "$@"
fi
exec foot "$@"
