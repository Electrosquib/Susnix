#!/usr/bin/env bash
# Build with the system qtermwidget package, or a temporary extracted Arch package.
set -euo pipefail
terminal_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
terminal_output="${1:-$terminal_repo/build/terminal/susnix-terminal}"
mkdir -p "$(dirname "$terminal_output")"
terminal_flags=()
if [[ -n "${SUSNIX_QTERMWIDGET_ROOT:-}" ]]; then
    terminal_flags=(-I"$SUSNIX_QTERMWIDGET_ROOT/usr/include/qtermwidget6" -L"$SUSNIX_QTERMWIDGET_ROOT/usr/lib" -lqtermwidget6)
else
    pkg-config --exists qtermwidget6 || { echo 'Install qtermwidget (sudo pacman -S --needed qtermwidget).' >&2;exit 1; }
    read -r -a terminal_flags <<< "$(pkg-config --cflags --libs qtermwidget6)"
fi
read -r -a terminal_qt <<< "$(pkg-config --cflags --libs Qt6Widgets)"
g++ -std=c++17 -O2 -fPIC -Wall -Wextra "$terminal_repo/apps/terminal/main.cpp" \
    "${terminal_qt[@]}" "${terminal_flags[@]}" -Wl,-rpath,'$ORIGIN/../lib/susnix-terminal' -o "$terminal_output"
echo "Built $terminal_output"
