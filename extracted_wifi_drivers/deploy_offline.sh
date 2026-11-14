#!/bin/bash
#
# ponwrt WiFi 离线部署脚本
# 适用于：Kernel 6.18.60 aarch64 (ImmortalWrt/OpenWrt)
# 设备：Nokia XG-040G-MD (UBI) 或同硬件平台
#
# 使用方法：
# 1. 将此目录完整复制到目标设备（如 /tmp/wifi_driver_pkg/）
# 2. 在目标设备上运行：bash deploy_offline.sh
# 3. 重启设备或手动加载模块
#

set -e

PKG_DIR="$(dirname "$0")"
KERNEL_VER="6.18.60"
MODULE_DIR="/lib/modules/$KERNEL_VER"
FIRMWARE_DIR="/lib/firmware"
MODULES_D_DIR="/etc/modules.d"

echo "============================================================"
echo "ponwrt WiFi 离线部署脚本"
echo "Kernel: $KERNEL_VER | Arch: aarch64"
echo "============================================================"

# 检查权限
if [[ $EUID -ne 0 ]]; then
    echo "错误: 需要 root 权限运行"
    exit 1
fi

# 检查内核版本匹配
running_kernel=$(uname -r)
if [[ "$running_kernel" != "$KERNEL_VER" ]]; then
    echo "警告: 运行内核 ($running_kernel) 与包内核 ($KERNEL_VER) 不匹配"
    echo "模块可能无法加载。建议在完全匹配的内核上使用。"
    read -p "继续部署? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# 1. 部署内核模块
echo "[1/5] 部署内核模块 (.ko)..."
if [[ -d "$PKG_DIR/modules" ]]; then
    mkdir -p "$MODULE_DIR"
    cp -v "$PKG_DIR/modules"/*.ko "$MODULE_DIR/"
    echo "  已复制 $(ls "$PKG_DIR/modules"/*.ko | wc -l) 个模块文件"
else
    echo "  错误: 找不到 modules 目录"
    exit 1
fi

# 2. 部署固件文件
echo "[2/5] 部署固件文件..."
if [[ -d "$PKG_DIR/firmware" ]]; then
    mkdir -p "$FIRMWARE_DIR"
    # 保持目录结构
    cp -rv "$PKG_DIR/firmware"/* "$FIRMWARE_DIR/"
    echo "  已复制固件文件"
else
    echo "  错误: 找不到 firmware 目录"
    exit 1
fi

# 3. 更新模块依赖
echo "[3/5] 更新模块依赖..."
depmod -a "$KERNEL_VER"
echo "  depmod 完成"

# 4. 配置模块自动加载
echo "[4/5] 配置模块自动加载 (/etc/modules.d/)..."
mkdir -p "$MODULES_D_DIR"

cat > "$MODULES_D_DIR/99-wifi-custom" << 'EOF'
# WiFi 驱动自动加载配置
# 按依赖顺序加载

# 802.11 核心栈
cfg80211
mac80211
compat

# Airoha PON/XGS-PON
airoha-en7572
airoha-pon-frontend-core
airoha-xpon

# Atheros AR9271/AR7010 USB
ath9k_htc

# MediaTek MT76 系列
mt7663u
mt76x2u
mt7921u
mt7925u

# Realtek RTL88xx USB (rtw88 系列)
rtw88_core
rtw88_8723d
rtw88_8723du
rtw88_8723x
rtw88_8812a
rtw88_8812au
rtw88_8814a
rtw88_8814au
rtw88_8821c
rtw88_8821cu
rtw88_8822b
rtw88_8822bu
rtw88_8822c
rtw88_8822cu
rtw88_88xxa
rtw88_usb
EOF

echo "  已创建 $MODULES_D_DIR/99-wifi-custom"

# 5. 安装用户空间工具包
echo "[5/5] 安装用户空间工具包..."
APK_DIR="$PKG_DIR/packages"
if [[ -d "$APK_DIR" ]]; then
    apk_files=( "$APK_DIR"/*.apk )
    if [[ -f "${apk_files[0]}" ]]; then
        echo "  发现 ${#apk_files[@]} 个 .apk 包，正在安装..."
        apk add --allow-untrusted "${apk_files[@]}" 2>&1 | tail -10
    else
        echo "  未发现 .apk 包，跳过（目标设备联网后可自动安装）"
    fi
else
    echo "  未找到 packages 目录"
fi

echo ""
echo "============================================================"
echo "部署完成！"
echo "============================================================"
echo ""
echo "后续步骤："
echo "1. 重启设备：reboot"
echo "   或手动加载模块："
echo "   for m in \$(cat $MODULES_D_DIR/99-wifi-custom | grep -v '^#' | grep -v '^$'); do modprobe \$m; done"
echo ""
echo "2. 检查 WiFi 设备："
echo "   iw dev"
echo "   lsmod | grep -E 'mt76|rtw|ath|airoha|cfg80211|mac80211'"
echo ""
echo "3. 配置 WiFi：编辑 /etc/config/wireless"
echo "   参考: $PKG_DIR/config/wireless_config.txt"
echo ""
echo "4. 如需安装缺失依赖包，联网后运行："
echo "   apk update && apk add wpad-mbedtls libmbedtls21 libubus20261028 ..."
echo "============================================================"
