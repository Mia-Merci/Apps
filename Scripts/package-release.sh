#!/usr/bin/env bash
set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
outputs_dir="$package_root/outputs"
app_path="$outputs_dir/CodexQuotaBar.app"
zip_path="$outputs_dir/CodexQuotaBar.zip"

"$package_root/Scripts/build-app.sh" >/dev/null

mkdir -p "$outputs_dir"
rm -f "$zip_path"
xattr -cr "$app_path" 2>/dev/null || true

ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "$app_path" "$zip_path"

echo "$zip_path"
