#!/bin/sh
# Offline WiFi Driver Deployment Script for ponwrt kernel 6.18.55
# Extracts kernel modules and firmware to target device
# Run as root on target device

set -e

TARGET_MODULES_DIR="/lib/modules/6.18.55"
TARGET_FIRMWARE_DIR="/lib/firmware"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== ponwrt WiFi Driver Offline Deployment (Kernel 6.18.55) ==="
echo "Script directory: $SCRIPT_DIR"
echo "Target modules dir: $TARGET_MODULES_DIR"
echo "Target firmware dir: $TARGET_FIRMWARE_DIR"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    exit 1
fi

# Verify source files exist
if [ ! -d "$SCRIPT_DIR/modules" ]; then
    echo "ERROR: modules/ directory not found in $SCRIPT_DIR"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/firmware" ]; then
    echo "ERROR: firmware/ directory not found in $SCRIPT_DIR"
    exit 1
fi

# Create target directories
mkdir -p "$TARGET_MODULES_DIR"
mkdir -p "$TARGET_FIRMWARE_DIR"

# Install kernel modules
echo "Installing kernel modules..."
MODULE_COUNT=0
for ko in "$SCRIPT_DIR/modules"/*.ko; do
    if [ -f "$ko" ]; then
        cp "$ko" "$TARGET_MODULES_DIR/"
        echo "  Installed: $(basename "$ko")"
        MODULE_COUNT=$((MODULE_COUNT + 1))
    fi
done
echo "  Total modules installed: $MODULE_COUNT"

# Install firmware files
echo "Installing firmware files..."
FIRMWARE_COUNT=0
cd "$SCRIPT_DIR/firmware"
find . -type f \( -name "*.bin" -o -name "*.fw" -o -name "*.elf.*" \) | while read f; do
    dest="$TARGET_FIRMWARE_DIR/$f"
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
    echo "  Installed: $f"
    FIRMWARE_COUNT=$((FIRMWARE_COUNT + 1))
done
echo "  Total firmware files installed: $FIRMWARE_COUNT"

# Update module dependencies
echo "Updating module dependencies..."
if command -v depmod >/dev/null 2>&1; then
    depmod -a 6.18.55
    echo "  depmod completed"
else
    echo "  WARNING: depmod not available, skipping"
fi

# Create modules.d entries for auto-loading
echo "Creating modules.d entries..."
MODULES_D="/etc/modules.d"
mkdir -p "$MODULES_D"

echo "cfg80211" > "$MODULES_D/99-wifi-cfg80211"
echo "mac80211" > "$MODULES_D/99-wifi-mac80211"
echo "compat" > "$MODULES_D/99-wifi-compat"
echo "hwmon" > "$MODULES_D/99-wifi-hwmon"

echo "mt76" > "$MODULES_D/99-wifi-mt76"
echo "mt76-usb" > "$MODULES_D/99-wifi-mt76-usb"
echo "mt76-connac-lib" > "$MODULES_D/99-wifi-mt76-connac-lib"
echo "mt792x-lib" > "$MODULES_D/99-wifi-mt792x-lib"
echo "mt792x-usb" > "$MODULES_D/99-wifi-mt792x-usb"
echo "mt7921-common" > "$MODULES_D/99-wifi-mt7921-common"
echo "mt7921u" > "$MODULES_D/99-wifi-mt7921u"
echo "mt7925-common" > "$MODULES_D/99-wifi-mt7925-common"
echo "mt7925u" > "$MODULES_D/99-wifi-mt7925u"

echo "rtw88_core" > "$MODULES_D/99-wifi-rtw88-core"
echo "rtw88_88xxa" > "$MODULES_D/99-wifi-rtw88-88xxa"
echo "rtw88_usb" > "$MODULES_D/99-wifi-rtw88-usb"
for chip in 8812a 8812au 8814a 8814au 8821a 8821au 8821c 8821cu 8822b 8822bu 8822c 8822cu; do
    echo "rtw88_$chip" > "$MODULES_D/99-wifi-rtw88-$chip"
done

echo "airoha-pon-frontend-core" > "$MODULES_D/99-wifi-airoha-pon-frontend"
echo "airoha-xpon" > "$MODULES_D/99-wifi-airoha-xpon"
echo "airoha-en7572" > "$MODULES_D/99-wifi-airoha-en7572"

echo "air_en8811h" > "$MODULES_D/99-wifi-air-en8811h"

echo "  modules.d entries created"

# Final verification
echo ""
echo "=== Deployment Summary ==="
echo "Kernel modules: $MODULE_COUNT"
echo "Firmware files: $FIRMWARE_COUNT"
echo ""
echo "To load WiFi drivers now, run:"
echo "  modprobe cfg80211 mac80211 compat hwmon"
echo "  modprobe mt76 mt76-usb mt76-connac-lib mt792x-lib mt792x-usb mt7921-common mt7921u mt7925-common mt7925u"
echo "  modprobe rtw88_core rtw88_88xxa rtw88_usb"
echo "  modprobe airoha-pon-frontend-core airoha-xpon airoha-en7572"
echo "  modprobe air_en8811h"
echo ""
echo "Or reboot the device for auto-loading via modules.d"
echo ""
echo "=== Deployment Complete ==="