#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v swift >/dev/null; then
  echo "需要 Swift 5.9+ 工具链；当前没有 swift。" >&2
  exit 2
fi
swift test
