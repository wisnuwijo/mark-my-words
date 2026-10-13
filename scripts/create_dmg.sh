#!/bin/bash
set -e

# MarkMyWord - macOS DMG Installer Creation Script
# Uses native macOS hdiutil to build a clean drag-and-drop installer

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MarkMyWord"
SOURCE_APP="${PROJECT_ROOT}/build/macos/Build/Products/Release/${APP_NAME}.app"
OUTPUT_DIR="${PROJECT_ROOT}/build"
DMG_NAME="${APP_NAME}-Installer.dmg"
OUTPUT_DMG="${OUTPUT_DIR}/${DMG_NAME}"
STAGING_DIR="${OUTPUT_DIR}/dmg_staging"
VOL_NAME="${APP_NAME} Installer"

echo "=========================================="
echo " Packaging ${APP_NAME} macOS Installer"
echo "=========================================="

# 1. Verify that the Release app bundle exists
if [ ! -d "${SOURCE_APP}" ]; then
  echo "Error: Release bundle not found at: ${SOURCE_APP}"
  echo "Please build the release app first: flutter build macos --release"
  exit 1
fi

echo "✓ Source app bundle found: ${SOURCE_APP}"

# 2. Clean previous build artifacts
echo "→ Cleaning previous staging directory and DMG..."
rm -rf "${STAGING_DIR}"
rm -f "${OUTPUT_DMG}"
mkdir -p "${STAGING_DIR}"

# 3. Copy app to staging directory
echo "→ Copying ${APP_NAME}.app to staging..."
cp -R "${SOURCE_APP}" "${STAGING_DIR}/${APP_NAME}.app"

# 4. Create symlink to /Applications for Drag-and-Drop installation
echo "→ Creating symlink to /Applications..."
ln -s /Applications "${STAGING_DIR}/Applications"

# 5. Create disk image using native hdiutil
echo "→ Building compressed disk image with hdiutil..."
hdiutil create \
  -volname "${VOL_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${OUTPUT_DMG}"

# 6. Clean up staging directory
rm -rf "${STAGING_DIR}"

# 7. Verification
if [ -f "${OUTPUT_DMG}" ]; then
  FILE_SIZE=$(ls -lh "${OUTPUT_DMG}" | awk '{print $5}')
  echo "=========================================="
  echo "✓ Successfully created DMG installer!"
  echo "  Location: ${OUTPUT_DMG}"
  echo "  Size:     ${FILE_SIZE}"
  echo "  Volume:   ${VOL_NAME}"
  echo "=========================================="
else
  echo "Error: Failed to create DMG."
  exit 1
fi
