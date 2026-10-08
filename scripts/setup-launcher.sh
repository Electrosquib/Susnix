#!/usr/bin/env bash
set -euo pipefail
launcher_user="${1:-${USER:-}}"
[[ -n "$launcher_user" ]] || { echo 'Specify the desktop user.' >&2;exit 1; }
if [[ $EUID -ne 0 && "$launcher_user" != "$USER" ]]; then echo 'Only root can install for another user.' >&2;exit 1;fi
launcher_home="$(getent passwd "$launcher_user" | cut -d: -f6)"
launcher_group="$(id -gn "$launcher_user")"
launcher_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
launcher_build="$(mktemp -d)";trap 'rm -rf -- "$launcher_build"' EXIT
read -r -a launcher_flags <<< "$(pkg-config --cflags --libs Qt6Gui)"
g++ -std=c++17 -O2 -fPIC -Wall -Wextra "$launcher_repo/apps/launcher/backdrop.cpp" "${launcher_flags[@]}" -o "$launcher_build/susnix-backdrop"
install -Dm0755 -o "$launcher_user" -g "$launcher_group" "$launcher_build/susnix-backdrop" "$launcher_home/.local/bin/susnix-backdrop"
