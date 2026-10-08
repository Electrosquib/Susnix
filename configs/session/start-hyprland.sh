# Sourced by the desktop user's Bash login profile.
# Leave terminal windows, SSH sessions, and recovery consoles alone.
if [[ $- == *i* && -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} && -z ${SSH_CONNECTION:-} ]] &&
    [[ "$(tty 2>/dev/null)" == /dev/tty1 ]] && command -v Hyprland >/dev/null 2>&1; then
    exec Hyprland
fi
