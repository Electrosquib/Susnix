#!/usr/bin/env bash
# Build native decorations against exactly the installed compositor headers.
set -euo pipefail
controls_user="${1:-${USER:-}}"
[[ -n "$controls_user" ]] || { echo 'Specify the desktop user.' >&2;exit 1; }
if [[ $EUID -ne 0 && "$controls_user" != "$USER" ]]; then
    echo 'Only root can install for another user.' >&2;exit 1
fi
controls_home="$(getent passwd "$controls_user" | cut -d: -f6)"
controls_group="$(id -gn "$controls_user")"
controls_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
controls_build="$(mktemp -d)";trap 'rm -rf -- "$controls_build"' EXIT
read -r -a controls_flags <<< "$(pkg-config --cflags pixman-1 libdrm hyprland libinput libudev wayland-server xkbcommon cairo)"
g++ -O2 -shared -fPIC -std=c++23 -fno-gnu-unique -Wno-narrowing "${controls_flags[@]}" \
    "$controls_repo/apps/window-controls/main.cpp" "$controls_repo/apps/window-controls/barDeco.cpp" \
    "$controls_repo/apps/window-controls/BarPassElement.cpp" $(pkg-config --libs cairo) -o "$controls_build/susnix-window-controls.so"
install -Dm0644 -o "$controls_user" -g "$controls_group" "$controls_build/susnix-window-controls.so" "$controls_home/.local/lib/susnix-window-controls.so.new"
mv -f "$controls_home/.local/lib/susnix-window-controls.so.new" "$controls_home/.local/lib/susnix-window-controls.so"
# A compositor update invalidates plugins; never load stale binaries after boot.
python - "$controls_build/susnix-window-controls.hash" <<'PY'
from pathlib import Path
import re,sys
header=Path('/usr/include/hyprland/src/version.h').read_text()
Path(sys.argv[1]).write_text(re.search(r'#define GIT_COMMIT_HASH\s+"([a-f0-9]+)"',header)[1]+'\n')
PY
install -Dm0644 -o "$controls_user" -g "$controls_group" "$controls_build/susnix-window-controls.hash" "$controls_home/.local/lib/susnix-window-controls.hash"
install -Dm0644 -o "$controls_user" -g "$controls_group" "$controls_repo/configs/hypr/window-controls.lua" "$controls_home/.config/hypr/window-controls.lua"
install -Dm0644 -o "$controls_user" -g "$controls_group" "$controls_repo/configs/hypr/window-controls.sh" "$controls_home/.config/susnix/window-controls.sh"
echo 'Low-profile global window controls installed.'
