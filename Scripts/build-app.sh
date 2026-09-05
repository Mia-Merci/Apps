#!/usr/bin/env bash
set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xcode_build_dir="$package_root/.build/xcodebuild"
built_app_dir="$xcode_build_dir/Build/Products/Release/CodexQuotaBar.app"
app_dir="$package_root/outputs/CodexQuotaBar.app"

cd "$package_root"
xcodebuild \
  -project CodexQuotaBar.xcodeproj \
  -scheme CodexQuotaBar \
  -configuration Release \
  -derivedDataPath "$xcode_build_dir" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build >/dev/null

rm -rf "$app_dir"
mkdir -p "$(dirname "$app_dir")"
ditto "$built_app_dir" "$app_dir"
codesign --force --deep --sign - "$app_dir" >/dev/null

echo "$app_dir"
