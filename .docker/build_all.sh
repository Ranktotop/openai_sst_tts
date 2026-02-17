#!/usr/bin/env bash
# Build & Push: GPU + CPU Images
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/build-gpu.sh" "$@"
"$SCRIPT_DIR/build-cpu.sh" "$@"