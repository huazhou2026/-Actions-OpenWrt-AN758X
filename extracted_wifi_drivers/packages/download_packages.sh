#!/usr/bin/env bash

REPOS=(
    "https://downloads.immortalwrt.org/snapshots/targets/airoha/an7581/packages"
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/base"
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/airoha"
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/pon_drivers"
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/packages"
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/luci"
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/routing"
)

OUTPUT_DIR="$(dirname "$0")"
PACKAGE_LIST="$OUTPUT_DIR/full_package_list.txt"
FAILED_LOG="$OUTPUT_DIR/download_failed.txt"
SUCCESS_LOG="$OUTPUT_DIR/download_success.txt"

# 读取包列表
packages=()
while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    packages+=("$line")
done < "$PACKAGE_LIST"

echo "发现 ${#packages[@]} 个包待下载"

# 检查已下载
existing=()
for f in "$OUTPUT_DIR"/*.apk; do
    [[ -f "$f" ]] && existing+=("$(basename "$f" .apk)")
done
echo "已存在 ${#existing[@]} 个 .apk 文件"

# 过滤已下载
to_download=()
for pkg in "${packages[@]}"; do
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

try_download() {
    local pkg="$1"
    for repo in "${REPOS[@]}"; do
        for url in "$repo/$pkg.apk" "$repo/packages/$pkg.apk"; do
            # HEAD 检查
            if curl -sI -f --max-time 10 "$url" >/dev/null 2>&1; then
                # 下载
                local out="$OUTPUT_DIR/$pkg.apk"
                if [[ -f "$out" ]]; then
                    curl -sL -C - --max-time 60 -o "$out" "$url" && return 0
                else
                    curl -sL --max-time 60 -o "$out" "$url" && return 0
                fi
            fi
        done
    done
    return 1
}

echo "开始下载..."
for pkg in "${to_download[@]}"; do
    if try_download "$pkg"; then
        ((success_count++))
        echo "✓ [$success_count/${#to_download[@]}] $pkg"
        echo -e "$pkg\t$url" >> "$SUCCESS_LOG"
    else
        failed+=("$pkg")
        echo "✗ FAILED: $pkg"
        echo "$pkg" >> "$FAILED_LOG"
    fi
done

echo "============================================================"
echo "下载完成: 成功 $success_count, 失败 ${#failed[@]}"
if [[ ${#failed[@]} -gt 0 ]]; then
    echo "失败列表已保存至: $FAILED_LOG"
    echo "失败的包可手动从软件源网页下载:"
    printf '  %s\n' "${failed[@]}"
fi
echo "============================================================"
