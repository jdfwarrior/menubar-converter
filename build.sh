#!/usr/bin/env bash
set -euo pipefail

# Simple build+package script for MBConverter
# - Builds the Swift package in MBConverter/
# - Creates a minimal .app bundle in dist/MBConverter.app

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$ROOT_DIR/MBConverter"
BUILD_CONFIG="release"

echo "Root: $ROOT_DIR"
echo "Package dir: $PKG_DIR"

cd "$PKG_DIR"

echo "Building Swift package (configuration: $BUILD_CONFIG)..."
swift build -c "$BUILD_CONFIG"

EXECUTABLE_PATH="$PKG_DIR/.build/$BUILD_CONFIG/MBConverter"
if [ ! -f "$EXECUTABLE_PATH" ]; then
  echo "Executable not found at $EXECUTABLE_PATH" >&2
  echo "Contents of .build/$BUILD_CONFIG:" >&2
  ls -la "$PKG_DIR/.build/$BUILD_CONFIG" || true
  exit 1
fi

DIST_DIR="$ROOT_DIR/dist"
APP_NAME="MBConverter"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Packaging into $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "Copying executable..."
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Detect HandBrakeCLI to fail early if missing (helpful for runtime)
echo "Detecting HandBrakeCLI..."
HB_OVERRIDE="${HAND_BRAKE_CLI_PATH:-}"
HB_CANDIDATES=("$HB_OVERRIDE" "/opt/homebrew/bin/HandBrakeCLI" "/usr/local/bin/HandBrakeCLI" "/usr/bin/HandBrakeCLI")
HB_FOUND=""
for p in "${HB_CANDIDATES[@]}"; do
  if [ -n "$p" ] && [ -x "$p" ]; then
    HB_FOUND="$p"
    break
  fi
done
if [ -z "$HB_FOUND" ]; then
  # try PATH lookup
  if command -v HandBrakeCLI >/dev/null 2>&1; then
    HB_FOUND="$(command -v HandBrakeCLI)"
  fi
fi

if [ -z "$HB_FOUND" ]; then
  cat 1>&2 <<'MSG'
HandBrakeCLI was not found on this machine. MBConverter requires HandBrakeCLI at runtime.
Install it with Homebrew (Intel):
  brew install handbrake
or (Apple Silicon/Homebrew default):
  arch -arm64 brew install handbrake
Or set the environment variable HAND_BRAKE_CLI_PATH to the full path to HandBrakeCLI.

The packaging step will stop so you can install HandBrakeCLI before running the app.
MSG
  exit 1
else
  echo "Found HandBrakeCLI at: $HB_FOUND"
fi

# Prefer Info.plist from Packaging/ then fallback to Resources, then create minimal
PLIST_SRC_PKG="$PKG_DIR/Packaging/Info.plist"
PLIST_SRC_RES="$PKG_DIR/Sources/MBConverter/Resources/Info.plist"
if [ -f "$PLIST_SRC_PKG" ]; then
  echo "Copying Info.plist from Packaging/Info.plist..."
  cp "$PLIST_SRC_PKG" "$CONTENTS_DIR/Info.plist"
elif [ -f "$PLIST_SRC_RES" ]; then
  echo "Copying Info.plist from Resources..."
  cp "$PLIST_SRC_RES" "$CONTENTS_DIR/Info.plist"
else
  echo "No Info.plist found; creating minimal Info.plist"
  cat > "$CONTENTS_DIR/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>MBConverter</string>
  <key>CFBundleIdentifier</key>
  <string>com.example.mbconverter</string>
  <key>CFBundleExecutable</key>
  <string>MBConverter</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
EOF
fi

# Copy extra resources (if any)
if [ -d "$PKG_DIR/Sources/MBConverter/Resources" ]; then
  echo "Copying Resources..."
  rsync -a --exclude='.DS_Store' "$PKG_DIR/Sources/MBConverter/Resources/" "$RESOURCES_DIR/" || true
fi

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "Package created: $APP_DIR"
echo "You can run it with: open '$APP_DIR'"

exit 0
