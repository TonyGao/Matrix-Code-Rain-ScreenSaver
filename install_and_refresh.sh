#!/bin/bash

# Configuration
PROJECT_NAME="Matrix Code Rain"
SAVER_NAME="${PROJECT_NAME}.saver"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCODE_PROJ="${PROJECT_DIR}/Matrix Code Rain/Matrix Code Rain.xcodeproj"
BIN_DIR="${PROJECT_DIR}/bin"
DEST_DIR="${HOME}/Library/Screen Savers"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[1/6] Building project...${NC}"
mkdir -p "${BIN_DIR}"
xcodebuild -project "${XCODE_PROJ}" -scheme "${PROJECT_NAME}" -configuration Debug clean build > /dev/null

# Get the actual build directory from xcodebuild
BUILD_DIR=$(xcodebuild -project "${XCODE_PROJ}" -scheme "${PROJECT_NAME}" -configuration Debug -showBuildSettings | grep -w "BUILT_PRODUCTS_DIR" | awk '{print $3}')

if [ ! -d "${BUILD_DIR}/${SAVER_NAME}" ]; then
    echo -e "${RED}Build failed! ${SAVER_NAME} not found in ${BUILD_DIR}${NC}"
    exit 1
fi

echo -e "${GREEN}[2/6] Syncing to project bin directory...${NC}"
cp -R "${BUILD_DIR}/${SAVER_NAME}" "${BIN_DIR}/"

echo -e "${GREEN}[3/6] Killing screen saver processes...${NC}"
killall "ScreenSaverEngine" 2>/dev/null
killall "legacyScreenSaver" 2>/dev/null
killall "System Settings" 2>/dev/null
killall "cfprefsd" 2>/dev/null # Flushes CoreFoundation preferences cache

echo -e "${GREEN}[4/6] Removing old screen saver from system...${NC}"
rm -rf "${DEST_DIR}/${SAVER_NAME}"

echo -e "${GREEN}[5/6] Installing from bin to system...${NC}"
mkdir -p "${DEST_DIR}"
cp -R "${BIN_DIR}/${SAVER_NAME}" "${DEST_DIR}/"

echo -e "${GREEN}[6/6] Touching file to force system refresh...${NC}"
touch "${DEST_DIR}/${SAVER_NAME}"

echo -e "${GREEN}Done! You can now open System Settings to preview.${NC}"
echo -e "If it still doesn't update, try running: /System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background"
