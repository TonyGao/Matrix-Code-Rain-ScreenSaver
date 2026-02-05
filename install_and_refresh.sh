#!/bin/bash

echo "[1/7] Building project..."
# Clean build folder first to ensure no stale artifacts
rm -rf build/
xcodebuild -project "Matrix Code Rain/Matrix Code Rain.xcodeproj" \
           -scheme "Matrix Code Rain" \
           -configuration Release \
           -derivedDataPath build \
           clean build

echo "[2/7] Syncing to project bin directory..."
mkdir -p bin
# Find the built .saver file (handle different possible output paths)
SAVER_PATH=$(find build -name "Matrix Code Rain.saver" -type d | head -n 1)

if [ -z "$SAVER_PATH" ]; then
    echo "Error: Could not find built .saver bundle"
    exit 1
fi

echo "Found built saver at: $SAVER_PATH"
rm -rf "bin/Matrix Code Rain.saver"
cp -R "$SAVER_PATH" bin/

echo "[3/7] Killing screen saver processes..."
killall ScreenSaverEngine 2>/dev/null
killall legacyScreenSaver 2>/dev/null
killall cfprefsd 2>/dev/null # Force preference reload

echo "[4/7] Removing old screen saver from system..."
rm -rf "$HOME/Library/Screen Savers/Matrix Code Rain.saver"

echo "[5/7] Installing from bin to system..."
cp -R "bin/Matrix Code Rain.saver" "$HOME/Library/Screen Savers/"

echo "[6/7] Touching file to force system refresh..."
touch "$HOME/Library/Screen Savers/Matrix Code Rain.saver"

echo "[7/7] Creating distribution zip..."
rm -f "bin/Matrix Code Rain.saver.zip"
cd bin
zip -r "Matrix Code Rain.saver.zip" "Matrix Code Rain.saver"
cd ..

echo "Zip package created at: $(pwd)/bin/Matrix Code Rain.saver.zip"

echo "Done! You can now open System Settings to preview."
echo "If it still doesn't update, try running: /System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background"
