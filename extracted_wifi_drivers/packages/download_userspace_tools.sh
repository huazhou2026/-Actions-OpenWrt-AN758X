#!/usr/bin/env bash

BASE_REPO="https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/base"
OUTPUT_DIR="$(dirname "$0")"
FAILED_LOG="$OUTPUT_DIR/userspace_failed.txt"
SUCCESS_LOG="$OUTPUT_DIR/userspace_success.txt"

# 用户空间工具包列表（从 base 源可用）
tools=(
    "iw-6.17-r1"
    "iwinfo-2026.05.26~66bdd1a0-r1"
    "hostapd-common-2026.08.07~831364bf-r4"
    "hostapd-mbedtls-2026.08.07~831364bf-r4"
    "wpad-mbedtls-2026.08.07~831364bf-r4"
    "libiwinfo20230701-2026.05.26~66bdd1a0-r1"
    "libiwinfo-data-2026.05.26~66bdd1a0-r1"
    "libnl-tiny1-2025.12.02~40493a65-r1"
    "libmbedtls21-3.6.3-r1"
    "libblobmsg-json20261103-2026.11.03-r1"
    "libubus20261028-2026.10.28-r1"
    "libuci20250120-2025.01.20-r1"
    "libucode20261009-2026.10.09-r1"
    "libudebug-2026.10.09-r1"
    "ucode-2026.10.09-r1"
    "ucode-mod-digest-2026.10.09-r1"
    "ucode-mod-nl80211-2026.10.09-r1"
    "ucode-mod-rtnl-2026.10.09-r1"
    "ucode-mod-ubus-2026.10.09-r1"
    "ucode-mod-uci-2026.10.09-r1"
    "ucode-mod-fs-2026.10.09-r1"
    "ucode-mod-uloop-2026.10.09-r1"
    "netifd-2026.11.03-r1"
    "wireless-regdb-2026.09.03-r1"
    "wifi-scripts-1.0-r4"
)

echo "发现 ${#tools[@]} 个用户空间工具包待下载"

# 检查已下载
existing=()
for f in "$OUTPUT_DIR"/*.apk; do
    [[ -f "$f" ]] && existing+=("$(basename "$f" .apk)")
done
echo "已存在 ${#existing[@]} 个 .apk 文件"

to_download=()
for pkg in "${tools[@]}"; do
    if [[ ! " ${existing[@]} " =~ " ${pkg} " ]]; then
        to_download+=("$pkg")
    fi
done

echo "需要下载: ${#to_download[@]} 个包"

if [[ ${#to_download[@]} -eq 0 ]]; then
    echo "所有包已下载完成！"
    exit 0
fi

success_count=0
failed=()

for pkg in "${to_download[@]}"; do
    url="$BASE_REPO/$pkg.apk"
    out="$OUTPUT_DIR/$pkg.apk"
    
    echo -n "下载 $pkg ... "
    if curl -sL -f --max-time 60 -o "$out" "$url"; then
        ((success_count++))
        echo "OK"
        echo -e "$pkg\t$url" >> "$SUCCESS_LOG"
    else
        failed+=("$pkg")
        echo "FAILED"
        echo "$pkg" >> "$FAILED_LOG"
        rm -f "$out"
    fi
done

echo "============================================================"
echo "用户空间工具包下载完成: 成功 $success_count, 失败 ${#failed[@]}"
if [[ ${#failed[@]} -gt 0 ]]; then
    echo "失败列表: ${failed[*]}"
fi
echo "============================================================"
