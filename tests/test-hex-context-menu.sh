#!/usr/bin/env bash
# Exercise the real QML component without touching desktop settings or windows.
set -euo pipefail
hex_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
hex_test="$(mktemp -d)"
trap 'rm -rf -- "$hex_test"' EXIT
mkdir -m700 "$hex_test/runtime" "$hex_test/config" "$hex_test/components" "$hex_test/services"
cp -a "$hex_repo/configs/quickshell/theme" "$hex_test/theme"
cp "$hex_repo/configs/quickshell/components/"{HexContextMenu,Icon,ElectricShock}.qml "$hex_test/components/"
cp "$hex_repo/configs/quickshell/services/collect.sh" "$hex_test/services/"
sed 's|../../configs/quickshell/components|components|' "$hex_repo/tests/hex-context-menu/shell.qml" > "$hex_test/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$hex_test/runtime" XDG_CONFIG_HOME="$hex_test/config" \
    timeout 10s quickshell -p "$hex_test" --no-duplicate > "$hex_test/output" 2>&1
cat "$hex_test/output"
rg -q 'HEX TEST PASS' "$hex_test/output"
# Qt's offscreen backend cannot set native window masks; real Wayland can.
if rg 'WARN|ERROR' "$hex_test/output" | rg -v 'This plugin does not support setting window masks'; then exit 1; fi
