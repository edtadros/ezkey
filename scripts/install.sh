#!/bin/zsh
# Install ezkey on this Mac.
# Builds from source, copies the app to /Applications/ezkey.app, and opens it.
# The app then registers Open at Login (System Settings → General → Login Items).
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT_DIR/scripts/build-and-run.sh"
