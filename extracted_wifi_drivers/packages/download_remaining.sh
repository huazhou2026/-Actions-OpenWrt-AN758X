#!/usr/bin/env bash

REPOS=(
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/packages"
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/base"
)

OUTPUT_DIR="$(dirname "$0")"
FAILED_LOG="$OUTPUT_DIR/remaining_failed.txt"

# 剩余缺失的包（尝试不同版本号）
packages=(
    "wpad-mbedtls-2026.08.07~831364bf-r4"
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
)

echo "尝试下载 ${#packages[@]} 个剩余包..."

success=0
failed=()

for pkg in "${packages[@]}"; do
    found=0
    for repo in "${REPOS[@]}"; do
        url="$repo/$pkg.apk"
        out="$OUTPUT_DIR/$pkg.apk"
        
        # HEAD 检查
        if curl -sI -f --max-time 10 "$url" >/dev/null 2>&1; then
            echo -n "下载 $pkg from $repo ... "
            if curl -sL -f --max-time 60 -o "$out" "$url"; then
                echo "OK"
                ((success++))
                found=1
                break
            fi
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        failed+=("$pkg")
        echo "NOT FOUND: $pkg"
    fi
done

echo "============================================================"
echo "补充下载完成: 成功 $success, 失败 ${#failed[@]}"
if [[ ${#failed[@]} -gt 0 ]]; then
    printf '%s\n' "${failed[@]}" > "$FAILED_LOG"
    echo "失败列表已保存至: $FAILED_LOG"
fi
echo "============================================================"
