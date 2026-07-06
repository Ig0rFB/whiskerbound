#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT" --path "$ROOT" --headless --import
"$GODOT" --path "$ROOT" --headless --script res://scenes/tools/tpc_sandbox_test.gd
