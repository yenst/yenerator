#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
omarchy_shell="${OMARCHY_PATH:-/usr/share/omarchy}/shell"
preview_dir=$(mktemp -d /tmp/yenerator-keyboard.XXXXXXXX)
trap 'rm -rf -- "$preview_dir"' EXIT
ln -s -- "$omarchy_shell/Commons" "$preview_dir/Commons"
ln -s -- "$omarchy_shell/Ui" "$preview_dir/Ui"
ln -s -- "$project_dir" "$preview_dir/Plugin"
cp -- "$project_dir/tests/keyboard.qml" "$preview_dir/shell.qml"
QT_QPA_PLATFORM=wayland timeout 15s quickshell -p "$preview_dir" --no-color >"$preview_dir/output.log" 2>&1
cat "$preview_dir/output.log"
# QtTest assertions in a Quickshell host do not set the process exit code.
# Require the explicit success marker emitted only after every assertion passes.
grep -q 'YENERATOR_KEYBOARD_OK' "$preview_dir/output.log"
