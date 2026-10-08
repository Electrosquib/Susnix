#!/usr/bin/env bash
set -euo pipefail
terminal_user="${1:-${USER:-}}"
[[ -n "$terminal_user" ]] || { echo 'Specify the desktop user.' >&2;exit 1; }
if [[ $EUID -ne 0 && "$terminal_user" != "$USER" ]]; then
    echo 'Only root can install for another user.' >&2;exit 1
fi
terminal_home="$(getent passwd "$terminal_user" | cut -d: -f6)"
terminal_group="$(id -gn "$terminal_user")"
terminal_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
terminal_assets="$terminal_home/.local/share/susnix-terminal"
terminal_build="$(mktemp -d)";trap 'rm -rf -- "$terminal_build"' EXIT
bash "$terminal_repo/scripts/build-terminal.sh" "$terminal_build/susnix-terminal"
install -Dm0755 -o "$terminal_user" -g "$terminal_group" "$terminal_build/susnix-terminal" "$terminal_home/.local/bin/susnix-terminal"
install -d -o "$terminal_user" -g "$terminal_group" "$terminal_assets/themes"
install -m0644 -o "$terminal_user" -g "$terminal_group" "$terminal_repo/configs/terminal/"* "$terminal_assets/"
install -m0644 -o "$terminal_user" -g "$terminal_group" "$terminal_repo/configs/quickshell/theme/themes/"*.json "$terminal_assets/themes/"
if [[ -n "${SUSNIX_QTERMWIDGET_ROOT:-}" ]]; then
    # Local VM installation without sudo; distro bootstrap uses the system package.
    install -d "$terminal_home/.local/lib/susnix-terminal" "$terminal_assets/kb-layouts"
    cp -a "$SUSNIX_QTERMWIDGET_ROOT/usr/lib/"libqtermwidget6.so* "$terminal_home/.local/lib/susnix-terminal/"
    cp -a "$SUSNIX_QTERMWIDGET_ROOT/usr/share/qtermwidget6/kb-layouts/"* "$terminal_assets/kb-layouts/"
fi
install -Dm0644 -o "$terminal_user" -g "$terminal_group" "$terminal_repo/apps/terminal/susnix-terminal.desktop" "$terminal_home/.local/share/applications/susnix-terminal.desktop"
# Desktop launchers do not all inherit ~/.local/bin in PATH.
python - "$terminal_home/.local/share/applications/susnix-terminal.desktop" "$terminal_home/.local/bin/susnix-terminal" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]);p.write_text(p.read_text().replace('Exec=susnix-terminal','Exec="'+sys.argv[2]+'"'))
PY
echo 'Susnix terminal installed. Super+Q opens it through the existing launcher.'
