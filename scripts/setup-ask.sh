#!/usr/bin/env bash
set -euo pipefail
ask_user="${1:-${USER:-}}"
[[ -n "$ask_user" ]] || { echo 'Specify the desktop user.' >&2; exit 1; }
if [[ $EUID -ne 0 && "$ask_user" != "$USER" ]]; then
    echo 'Only root can install for another user.' >&2; exit 1
fi
ask_home="$(getent passwd "$ask_user" | cut -d: -f6)"
[[ -n "$ask_home" ]] || { echo 'User home was not found.' >&2; exit 1; }
ask_group="$(id -gn "$ask_user")"
ask_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
install -Dm0755 -o "$ask_user" -g "$ask_group" "$ask_repo/apps/ask/ask.py" "$ask_home/.local/bin/ask"
# Native Susnix Terminal also sources this file. Preserve existing shell setup.
python3 - "$ask_home/.bashrc" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
marker = '# Susnix CLI tools on PATH.'
old = path.read_text() if path.exists() else ''
if marker not in old:
    with path.open('a') as file:
        file.write('\n' + marker + '\n')
        file.write('case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac\n')
PY
if [[ $EUID -eq 0 ]]; then
    chown "$ask_user:$ask_group" "$ask_home/.bashrc"
fi
echo 'Installed ask. Open a new terminal or run: export PATH="$HOME/.local/bin:$PATH"'
