#!/bin/sh
# Build the WWDCBuddy Raycast extension into a prebuilt bundle and place it where
# the macOS app expects it (Contents/Resources/wwdcbuddy-raycast).
#
# Usage:
#   script/bundle_raycast_extension.sh <output_dir>
#
# When run from the Xcode "Bundle Raycast Extension" phase, <output_dir> points
# into the built app. If npm is available the extension is rebuilt from source;
# otherwise the committed prebuilt fallback (raycast-extension-prebuilt) is used.
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=${SRCROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}
EXT_SRC="$REPO_ROOT/raycast-extension"
PREBUILT_FALLBACK="$REPO_ROOT/raycast-extension-prebuilt"

OUTPUT_DIR=${1:-"$PREBUILT_FALLBACK"}

mkdir -p "$(dirname "$OUTPUT_DIR")"
rm -rf "$OUTPUT_DIR"

if command -v npm >/dev/null 2>&1 && [ -d "$EXT_SRC" ]; then
  echo "Building Raycast extension from source -> $OUTPUT_DIR"
  ( cd "$EXT_SRC" && { [ -d node_modules ] || npm ci; } && npx ray build -e dist -o "$OUTPUT_DIR" )
elif [ -d "$PREBUILT_FALLBACK" ]; then
  echo "npm not found; using committed prebuilt fallback -> $OUTPUT_DIR"
  cp -R "$PREBUILT_FALLBACK" "$OUTPUT_DIR"
else
  echo "warning: could not build or find a prebuilt Raycast extension" >&2
  exit 0
fi

# Source maps are not needed inside the shipped app.
find "$OUTPUT_DIR" -name "*.js.map" -delete 2>/dev/null || true
echo "Raycast extension bundled at $OUTPUT_DIR"
