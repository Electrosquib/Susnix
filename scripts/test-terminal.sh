#!/usr/bin/env bash
set -euo pipefail
terminal_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
terminal_build="$(mktemp -d)";trap 'rm -rf -- "$terminal_build"' EXIT
terminal_flags=()
if [[ -n "${SUSNIX_QTERMWIDGET_ROOT:-}" ]]; then
    terminal_flags=(-I"$SUSNIX_QTERMWIDGET_ROOT/usr/include/qtermwidget6" -L"$SUSNIX_QTERMWIDGET_ROOT/usr/lib" -lqtermwidget6)
    export LD_LIBRARY_PATH="$SUSNIX_QTERMWIDGET_ROOT/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
else
    read -r -a terminal_flags <<< "$(pkg-config --cflags --libs qtermwidget6)"
fi
read -r -a terminal_qt <<< "$(pkg-config --cflags --libs Qt6Widgets)"
mkdir -p "$terminal_build/themes"
cp "$terminal_repo/configs/quickshell/theme/themes/"*.json "$terminal_build/themes/"
for test_name in pty theme; do
    g++ -std=c++17 -O2 -fPIC -Wall -Wextra "$terminal_repo/apps/terminal/$test_name-smoke.cpp" \
        "${terminal_qt[@]}" "${terminal_flags[@]}" -o "$terminal_build/$test_name-test"
    QT_QPA_PLATFORM=offscreen "$terminal_build/$test_name-test" "$terminal_build"
done
