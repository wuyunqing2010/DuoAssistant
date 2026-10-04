#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null; then
  echo "需要在安装完整 Xcode 的 Mac 上运行；当前没有 xcodebuild。" >&2
  exit 2
fi
xcodebuild -project PurchaseAssistant.xcodeproj -scheme PurchaseAssistant \
  -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
