#!/bin/zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT_DIR/site/images}"
cd "$ROOT_DIR"
SKIP_TESTS="${SKIP_TESTS:-1}" SKIP_LAUNCH=1 SKIP_VERIFY=1 "$ROOT_DIR/scripts/build-and-run.sh"
"$ROOT_DIR/build/ezkey.app/Contents/MacOS/ezkey" --render-marketing "$OUT"
