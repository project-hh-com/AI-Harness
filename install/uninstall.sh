#!/usr/bin/env bash
# v7 AI-Harness 제거 (install.sh --uninstall의 단축 진입점)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/install.sh" --uninstall "$@"
