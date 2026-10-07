#!/usr/bin/env bash
# Optional providers are quiet when absent, disconnected, or unsupported.
# Bound command duration so a stalled provider cannot stop future updates.
export LC_ALL=C
case "${1:-}" in
    gpu)
        provider_failed=false
        if command -v nvidia-smi >/dev/null 2>&1; then
            gpu_output="$(timeout 2s nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null)"
            gpu_values=()
            while read -r value; do
                [[ "$value" =~ ^[0-9]+$ ]] && gpu_values+=("$value")
            done <<< "$gpu_output"
            if (( ${#gpu_values[@]} )); then
                printf '%s\n' "${gpu_values[@]}"
                exit 0
            fi
            provider_failed=true
        fi
        # AMD exposes a percentage directly; no driver package or privilege needed.
        found_counter=false
        for counter in /sys/class/drm/card[0-9]*/device/gpu_busy_percent; do
            [[ -r "$counter" ]] || continue
            read -r value < "$counter" || continue
            if [[ "$value" =~ ^[0-9]+$ ]]; then
                printf '%s\n' "$value"
                found_counter=true
            fi
        done
        [[ "$found_counter" == true ]] && exit 0
        for driver in /sys/class/drm/card[0-9]*/device/driver; do
            driver_name="$(readlink "$driver" 2>/dev/null)"
            case "${driver_name##*/}" in
                vmwgfx|vboxvideo|virtio_gpu|qxl) printf '%s\n' virtual; exit 0 ;;
                nvidia) provider_failed=true ;;
            esac
        done
        if [[ "$provider_failed" == true ]]; then
            printf '%s\n' error
        else
            printf '%s\n' unavailable
        fi
        ;;
    audio)
        if command -v wpctl >/dev/null 2>&1; then
            timeout 2s wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true
        fi
        ;;
    network)
        if command -v nmcli >/dev/null 2>&1; then
            timeout 2s nmcli --terse --fields TYPE,STATE device status 2>/dev/null || true
        fi
        ;;
    init-resources)
        config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/susnix"
        umask 077
        mkdir -p "$config_dir" || exit 1
        if [[ ! -e "$config_dir/resource-tasks.json" ]]; then
            resource_temp="$(mktemp "$config_dir/.resources.XXXXXX")" || exit 1
            cat "$2" > "$resource_temp" || { rm -f "$resource_temp"; exit 1; }
            ln "$resource_temp" "$config_dir/resource-tasks.json" 2>/dev/null || true
            rm -f "$resource_temp"
        fi
        ;;
    init-theme)
        theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/susnix"
        umask 077
        mkdir -p "$theme_dir" || exit 1
        if [[ ! -e "$theme_dir/colors.json" ]]; then
            theme_temp="$(mktemp "$theme_dir/.colors.XXXXXX")" || exit 1
            if ! cat "$2" > "$theme_temp"; then
                rm -f "$theme_temp"
                exit 1
            fi
            # Publish a complete file atomically without replacing existing settings.
            ln "$theme_temp" "$theme_dir/colors.json" 2>/dev/null || true
            rm -f "$theme_temp"
        fi
        ;;
    init-task)
        task_dir="$HOME/.local/state/susnix"
        umask 077
        mkdir -p "$task_dir" || exit 1
        # noclobber protects existing state, including simultaneous monitor starts.
        if [[ ! -e "$task_dir/task.json" ]]; then
            (set -o noclobber; printf '%s\n' '{"task":"Implement top bar"}' > "$task_dir/task.json") 2>/dev/null || true
        fi
        ;;
    *) exit 2 ;;
esac
