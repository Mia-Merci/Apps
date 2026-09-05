#!/usr/bin/env bash
set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$package_root/.build/release"
cache_dir="$package_root/.build/cache"
app_dir="$package_root/outputs/CodexQuotaBar.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
icon_path="$package_root/Resources/CodexQuotaBar.icns"

cd "$package_root"
mkdir -p "$cache_dir/clang-module-cache" "$cache_dir/swiftpm-module-cache"
export CLANG_MODULE_CACHE_PATH="$cache_dir/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$cache_dir/swiftpm-module-cache"
swift build --disable-sandbox -c release

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"
cp "$build_dir/CodexQuotaBar" "$macos_dir/CodexQuotaBar"
cp "$icon_path" "$resources_dir/CodexQuotaBar.icns"

cat > "$contents_dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIconFile</key>
  <string>CodexQuotaBar</string>
  <key>CFBundleExecutable</key>
  <string>CodexQuotaBar</string>
  <key>CFBundleIdentifier</key>
  <string>local.codex.quota-bar</string>
  <key>CFBundleName</key>
  <string>CodexQuotaBar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

echo "$app_dir"
