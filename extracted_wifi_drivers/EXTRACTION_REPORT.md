# ponwrt WiFi Drivers Extraction Report

## Device Information
- **Model**: Nokia XG-040G-MD (UBI)
- **Firmware**: ImmortalWrt (OpenWrt-based)
- **Kernel**: 6.18.60 (aarch64 Cortex-A53)
- **Build Date**: 2026-11-07
- **Management IP**: 192.168.2.1
- **Login**: root / root

## Extracted Files Summary

### 📁 Kernel Modules (`modules/`) - 36 files
Total: ~5.4 MB

| Category | Modules | Key Files |
|----------|---------|-----------|
| **Airoha PON** | 4 | `air_en8811h.ko`, `airoha-en7572.ko`, `airoha-pon-frontend-core.ko`, `airoha-xpon.ko` |
| **Atheros AR9271/AR7010** | 4 | `ath.ko`, `ath9k_common.ko`, `ath9k_htc.ko`, `ath9k_hw.ko` |
| **802.11 Stack** | 3 | `cfg80211.ko`, `mac80211.ko`, `compat.ko` |
| **MediaTek MT76 Family** | 13 | `mt76.ko`, `mt76-usb.ko`, `mt76-connac-lib.ko`, `mt7615-common.ko`, `mt7663u.ko`, `mt7663-usb-sdio-common.ko`, `mt76x2u.ko`, `mt76x2-common.ko`, `mt76x02-usb.ko`, `mt76x02-lib.ko`, `mt7921u.ko`, `mt7921-common.ko`, `mt7925u.ko`, `mt7925-common.ko`, `mt792x-lib.ko`, `mt792x-usb.ko` |
| **Realtek RTL88xx (rtw88)** | 22 | `rtw88_core.ko`, `rtw88_usb.ko`, `rtw88_8812a.ko`, `rtw88_8812au.ko`, `rtw88_8814a.ko`, `rtw88_8814au.ko`, `rtw88_8821c.ko`, `rtw88_8821cu.ko`, `rtw88_8822b.ko`, `rtw88_8822bu.ko`, `rtw88_8822c.ko`, `rtw88_8822cu.ko`, `rtw88_8723d.ko`, `rtw88_8723du.ko`, `rtw88_8723x.ko`, `rtw88_88xxa.ko` |

### 📁 Firmware Files (`firmware/`) - 20 files
Total: ~2.2 MB

| Vendor | Files |
|--------|-------|
| **Airoha** | `EthMD32.DSP.bin`, `EthMD32.dm.bin`, `en7581_npu_data.bin`, `en7581_npu_rv32.bin`, `en7572/A60993.elf.dm`, `en7572/A60993.elf.pm` |
| **Atheros** | `ath9k_htc/htc_7010-1.4.0.fw`, `ath9k_htc/htc_9271-1.4.0.fw` |
| **MediaTek** | `WIFI_MT7922_patch_mcu_1_1_hdr.bin`, `WIFI_MT7961_patch_mcu_1_2_hdr.bin`, `WIFI_RAM_CODE_MT7922_1.bin`, `WIFI_RAM_CODE_MT7961_1.bin`, `mt7662.bin`, `mt7662_rom_patch.bin` |
| **Realtek** | `rtw8723d_fw.bin`, `rtw8812a_fw.bin`, `rtw8814a_fw.bin`, `rtw8821c_fw.bin`, `rtw8822b_fw.bin`, `rtw8822c_fw.bin`, `rtw8822c_wow_fw.bin` |

### 📁 Configuration & Documentation (`config/`) - 7 files
- `system_info.txt` - Complete system/hardware info
- `wireless_config.txt` - `/etc/config/wireless` (radio0 disabled 2.4G, radio1 5G AP)
- `network_config.txt` - `/etc/config/network` (PPPoE WAN, bridge LAN)
- `board_info.json` - Hardware definition (3x3 MIMO, 2G/5G/6G support)
- `wifi_packages_manifest.txt` - 62 package names with versions for apk reinstall
- `modules_load_order.txt` - Auto-load order + full dependency graph
- `loaded_modules_full.txt` - Complete lsmod output with usage counts

## WiFi Hardware Capabilities (from board.json)
- **Antenna**: 3×3 MIMO (3 Rx, 3 Tx)
- **2.4 GHz**: HT, HE (WiFi 6), max 40 MHz width
- **5 GHz**: HT, VHT, HE (WiFi 6), max 80 MHz width  
- **6 GHz**: HE (WiFi 6E), max 80 MHz width
- **USB Path**: `platform/soc/1fad0000.usb/usb3/3-1/3-1:1.3`

## Package Sources (for reinstallation)
```
https://downloads.immortalwrt.org/snapshots/targets/airoha/an7581/packages
https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/base
https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/airoha
https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/pon_drivers
https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/packages
```

## Usage Notes
1. **Kernel modules** require matching kernel 6.18.60 aarch64
2. **Firmware files** go to `/lib/firmware/` preserving directory structure
3. **Module load order** must respect dependencies (see `modules_load_order.txt`)
4. **Package manifest** enables full reinstall via `apk add <packages>`
5. Current config: radio0 (2.4G) disabled, radio1 (5G) as open AP "ImmortalWrt"

## Extraction Method
- SSH connection via PuTTY plink.exe
- Base64-encoded tar.gz streaming for binary transfer
- All files verified extracted successfully
