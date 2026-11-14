# PonWrt USB WiFi 定制固件构建指南

## 📋 项目概述

为 **Nokia XG-040G-MD (UBI)** 光猫（Airoha AN7581 SoC，aarch64_cortex-a53）构建基于 **ponwrt** + **ztb666ai/Actions-OpenWrt-AN758X** 的定制固件，包含：

- ✅ **OpenClash** 代理支持
- ✅ **完整 USB 无线驱动栈**（RTL8814AU, MT7612, MT7921, 通用 USB 无线网卡）
- ✅ **双 USB 口支持**（USB 3.0 xHCI + UAS + usb-storage）
- ✅ **APK 包管理**（全量签名）
- ✅ **nftables 全栈网络**（无 iptables）

---

## 🎯 支持的 USB 无线网卡芯片

| 厂商 | 芯片型号 | 驱动包 | 适用场景 |
|------|----------|--------|----------|
| **Realtek** | RTL8814AU (USB 3.0, 4x4 AC) | `kmod-rtw88-8814au` | 高性能 WiFi 5 AP/客户端 |
| **Realtek** | RTL8812CU / RTL8821CU / RTL8822CU / RTL88x2CU | `kmod-rtl8812cu` `kmod-rtl8821cu` `kmod-rtl88x2cu` | 常见 USB 无线网卡 (AC1200/AC1300/AC2100) |
| **MediaTek** | MT7612U / MT76x2U (USB 2.0, 2x2 AC) | `kmod-mt76x2u` | 经典 USB WiFi 5 网卡 |
| **MediaTek** | MT7916U (WiFi 6E, 2x2) | `kmod-mt7916u` | WiFi 6E 双频 |
| **MediaTek** | MT7921U (WiFi 6, 2x2) | `kmod-mt7921u` | WiFi 6 双频 |
| **MediaTek** | MT7925U (WiFi 6E, 2x2) | `kmod-mt7925u` | WiFi 6E 双频 |
| **Atheros** | AR9271 / AR7010 (USB 2.0, 1x1 N) | `kmod-ath9k-htc` | 老旧 USB WiFi 4 网卡 |

---

## 📁 文件清单

```
ponwrt wifi driver/
├── nokia_xg-040g-md-ubi-usbwifi.config   # 机型精简配置（含 USB 无线驱动）
├── diy-part1-usbwifi.sh                   # 插件拉取脚本（已启用 OpenClash）
├── build-usbwifi.yml                      # GitHub Actions 工作流
└── README_USB_WIFI_BUILD.md               # 本文档
```

---

## 🚀 快速开始：GitHub Actions 云端构建（推荐）

### 方法一：Fork 仓库并使用 Actions（零本地环境）

1. **Fork 基础仓库**
   - 访问 https://github.com/ztb666ai/Actions-OpenWrt-AN758X
   - 点击右上角 **Fork** → 你的账号下创建副本

2. **上传自定义文件**
   - 在你 Fork 的仓库中，将以下 3 个文件上传到仓库根目录：
     - `nokia_xg-040g-md-ubi-usbwifi.config` → 重命名为 `configs/nokia_xg-040g-md-ubi-usbwifi.config`
     - `diy-part1-usbwifi.sh` → 重命名为 `diy-part1-usbwifi.sh`
     - `build-usbwifi.yml` → 放入 `.github/workflows/build-usbwifi.yml`

3. **触发构建**
   - 进入你 Fork 的仓库 **Actions** 标签页
   - 选择 **"Build PonWrt USB WiFi (Nokia XG-040G-MD UBI + OpenClash)"**
   - 点击 **Run workflow** → 选择参数 → **Run workflow**
   - 参数建议：
     - `source`: `fork`（使用你 Fork 的 ponwrt 仓库）
     - `branch`: `master`
     - `upload_release`: `true`
     - `fw_author`: `yourname`（显示在 LuCI 固件版本中）

4. **下载固件**
   - 构建完成后（约 40-90 分钟），在 **Artifacts** 或 **Releases** 页面下载
   - 固件文件名类似：`ponwrt-an7581-nokia_xg-040g-md-ubi-openclash-usbwifi-*.itb`

### 方法二：使用原仓库的 workflow_dispatch（无需 Fork ponwrt）

如果你不想维护 ponwrt 分支，可以直接在 ztb666ai/Actions-OpenWrt-AN758X 仓库（需有写权限）或你的 Fork 中：

1. 将 `build-usbwifi.yml` 放入 `.github/workflows/`
2. 将配置文件放入 `configs/`
3. 将 `diy-part1-usbwifi.sh` 放入根目录
4. 在 Actions 中运行该 workflow

---

## 🛠 本地构建（高级用户）

### 环境要求
- Ubuntu 22.04/24.04 (或 WSL2)
- 磁盘 ≥ 50GB 可用空间
- 内存 ≥ 8GB (建议 16GB+)
- CPU 核心数越多越快

### 步骤

```bash
# 1. 安装依赖
sudo apt update && sudo apt install -y \
  build-essential clang llvm dwarves libssl-dev libelf-dev \
  bc flex bison python3 python3-distutils xz-utils tar unzip zip \
  zstd dos2unix ccache gettext rsync file wget curl git subversion

# 2. 配置 Swap（编译内核需要）
sudo swapoff -a 2>/dev/null || true
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile

# 3. 克隆源码
git clone https://github.com/ztb666ai/ponwrt -b master --single-branch --depth=1 openwrt
cd openwrt

# 4. 复制自定义配置
cp ../nokia_xg-040g-md-ubi-usbwifi.config configs/nokia_xg-040g-md-ubi.config
cp ../diy-part1-usbwifi.sh diy-part1.sh

# 5. 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 6. 运行 diy-part1.sh（拉取 OpenClash 等插件）
chmod +x diy-part1.sh
./diy-part1.sh

# 7. 加载配置
cp configs/an7581.config .config
cat configs/nokia_xg-040g-md-ubi.config >> .config

# 8. 裁剪机型
sed -i '/CONFIG_TARGET_DEVICE_/d; /^CONFIG_TARGET_MULTI_PROFILE=/d' .config
cat >> .config <<'EOF'
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_DEVICE_airoha_an7581_DEVICE_nokia_xg-040g-md-ubi=y
CONFIG_TARGET_DEVICE_PACKAGES_airoha_an7581_DEVICE_nokia_xg-040g-md-ubi=""
EOF

# 9. 注入内核 crypto 配置（AN7581 软 AES）
KCONF="target/linux/airoha/an7581/config-6.18"
for key in CRYPTO_AES CRYPTO_AES_ARM64 CRYPTO_AES_ARM64_BS CRYPTO_AES_ARM64_NEON_BLK \
  CRYPTO_SIMD CRYPTO_CBC CRYPTO_CTR CRYPTO_XTS CRYPTO_GHASH CRYPTO_GCM \
  CRYPTO_HW CRYPTO_DEV_EIP93 CRYPTO_AUTHENC \
  CRYPTO_DEV_EIP93_AES_128_SW_MAX_LEN CRYPTO_DEV_EIP93_GENERIC_SW_MAX_LEN; do
  sed -i -e "/^CONFIG_${key}=/d" -e "/^# CONFIG_${key} is not set$/d" "$KCONF"
done
cat >> "$KCONF" <<'EOF'
CONFIG_CRYPTO_AES=y
CONFIG_CRYPTO_AES_ARM64=y
CONFIG_CRYPTO_AES_ARM64_BS=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_SIMD=y
CONFIG_CRYPTO_CBC=y
CONFIG_CRYPTO_CTR=y
CONFIG_CRYPTO_XTS=y
CONFIG_CRYPTO_GHASH=y
CONFIG_CRYPTO_GCM=y
CONFIG_CRYPTO_HW=y
CONFIG_CRYPTO_DEV_EIP93=m
CONFIG_CRYPTO_AUTHENC=y
CONFIG_CRYPTO_DEV_EIP93_AES_128_SW_MAX_LEN=512
CONFIG_CRYPTO_DEV_EIP93_GENERIC_SW_MAX_LEN=256
EOF

# 10. 运行 diy-part2.sh 和 diy-part3.sh
chmod +x ../diy-part2.sh ../diy-part3.sh
# 从 ztb666ai 仓库获取 diy-part2.sh 和 diy-part3.sh，或使用原仓库的
# 这里假设已下载到上级目录
../diy-part2.sh
KEEP="base luci-app-airoha-npu luci-app-openclash" ../diy-part3.sh

# 11. 注入 OpenClash 配置
sed -i '/^CONFIG_PACKAGE_luci-app-openclash=/d; /^# CONFIG_PACKAGE_luci-app-openclash is not set/d' .config
sed -i '/^CONFIG_PACKAGE_luci-compat=/d; /^# CONFIG_PACKAGE_luci-compat is not set/d' .config
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
echo "CONFIG_PACKAGE_luci-compat=y" >> .config
for pkg in ca-bundle curl libopenssl ruby ruby-yaml ruby-json ruby-base64; do
  sed -i "/^CONFIG_PACKAGE_${pkg}=/d; /^# CONFIG_PACKAGE_${pkg} is not set/d" .config
  echo "CONFIG_PACKAGE_${pkg}=y" >> .config
done

# 12. 最终 defconfig
make defconfig

# 13. 下载依赖并编译
make download -j$(nproc)
make -j$(nproc) V=s

# 14. 产物在 bin/targets/airoha/an7581/
ls -la bin/targets/airoha/an7581/
```

---

## 🔧 关键配置说明

### nokia_xg-040g-md-ubi-usbwifi.config 核心变更

相比原版 `nokia_xg-040g-md-ubi.config`（无 WiFi 版），主要新增：

```bash
# === 无线核心栈 ===
CONFIG_PACKAGE_kmod-mac80211=y
CONFIG_PACKAGE_kmod-cfg80211=y
CONFIG_PACKAGE_kmod-mt76-core=y
CONFIG_PACKAGE_kmod-mt76-connac=y
CONFIG_PACKAGE_wpad-openssl=y
CONFIG_PACKAGE_hostapd-common=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y

# === MediaTek USB WiFi ===
CONFIG_PACKAGE_kmod-mt76-usb=y
CONFIG_PACKAGE_kmod-mt76x02-lib=y
CONFIG_PACKAGE_kmod-mt76x02-usb=y
CONFIG_PACKAGE_kmod-mt76x2-common=y
CONFIG_PACKAGE_kmod-mt76x2u=y          # MT7612/MT76x2U
CONFIG_PACKAGE_kmod-mt7916u=y          # MT7916U (WiFi 6E)
CONFIG_PACKAGE_kmod-mt7921u=y          # MT7921U (WiFi 6)
CONFIG_PACKAGE_kmod-mt7925u=y          # MT7925U (WiFi 6E)
CONFIG_PACKAGE_kmod-mt792x-lib=y
CONFIG_PACKAGE_kmod-mt792x-usb=y

# === Realtek USB WiFi ===
CONFIG_PACKAGE_kmod-rtw88-core=y
CONFIG_PACKAGE_kmod-rtw88-usb=y
CONFIG_PACKAGE_kmod-rtw88-8814au=y     # RTL8814AU (重点)
CONFIG_PACKAGE_kmod-rtl8812cu=y
CONFIG_PACKAGE_kmod-rtl8821cu=y
CONFIG_PACKAGE_kmod-rtl88x2cu=y

# === Atheros USB WiFi ===
CONFIG_PACKAGE_kmod-ath=y
CONFIG_PACKAGE_kmod-ath9k-hw=y
CONFIG_PACKAGE_kmod-ath9k-common=y
CONFIG_PACKAGE_kmod-ath9k-htc=y        # AR9271/AR7010
```

### diy-part1-usbwifi.sh 关键变更

```bash
# 启用 OpenClash
readonly ADD_OPENCLASH=true

# 必装插件校验新增 luci-app-openclash
CRITICAL_PKGS=(luci-app-airoha-npu luci-app-openclash)
```

---

## 📦 刷机指南

### 固件格式说明
- **`.itb`** (FIT Image)：**推荐用于 UBI 分区设备**（Nokia XG-040G-MD UBI）
- 通过 `sysupgrade` 或 `fwtool` 刷写

### 刷机步骤（SSH 方式）

```bash
# 1. 上传固件到光猫 /tmp
scp ponwrt-an7581-nokia_xg-040g-md-ubi-*.itb root@192.168.1.1:/tmp/

# 2. 刷写（保留配置）
ssh root@192.168.1.1 "sysupgrade -n /tmp/ponwrt-an7581-nokia_xg-040g-md-ubi-*.itb"

# 或不保留配置（全新安装）
ssh root@192.168.1.1 "sysupgrade /tmp/ponwrt-an7581-nokia_xg-040g-md-ubi-*.itb"
```

### 刷机后验证 USB 无线

```bash
# 1. 插入 USB 无线网卡
# 2. 查看内核识别
dmesg -T | grep -i -e usb -e wlan -e phy

# 3. 查看加载的模块
lsmod | grep -E "mt76|rtw88|ath9k|cfg80211|mac80211"

# 4. 查看无线接口
iw dev
# 应看到 phy0/phy1 等，对应 wlan0/wlan1

# 5. 测试扫描（以 RTL8814AU 为例）
iw phy phy0 interface add wlan0 type managed
ip link set wlan0 up
iw wlan0 scan | grep -E "SSID|signal"

# 6. LuCI 配置：网络 → 无线 → 添加/编辑无线网络
```

---

## ⚠️ 常见问题与排查

### Q1: 编译失败 "luci-app-openclash 未进索引"
**原因**：OpenClash 依赖 Ruby/Rust 工具链，首次编译极慢且易超时。
**解决**：
- 确保 `USE_DL_CACHE=true` 复用下载缓存
- 首次建议先跑 `toolchain-only` 预热缓存（workflow 中 `scope: toolchain-only`）
- 增加 `timeout-minutes: 350`（已在 workflow 中设置）

### Q2: USB 无线网卡插上无反应
**排查步骤**：
```bash
# 1. 确认 USB 供电正常（XG-040G-MD 双口 5V 可控）
cat /sys/kernel/debug/usb/devices  # 查看设备是否枚举

# 2. 确认固件文件存在
ls /lib/firmware/mediatek/   # MT79xx 固件
ls /lib/firmware/rtw88/      # Realtek 固件
ls /lib/firmware/ath9k_htc/  # Atheros 固件

# 3. 手动加载模块测试
modprobe mt76x2u      # MT7612
modprobe rtw88_8814au # RTL8814AU
modprobe ath9k_htc    # AR9271

# 4. 查看 dmesg 错误
dmesg -T | tail -30
```

### Q3: 固件体积过大导致刷机失败
**优化建议**：
- 在 `.config` 中移除不需要的语言包、主题、调试工具
- 关闭 `CONFIG_DEVEL=y`（会移除编译工具链）
- 使用 `CONFIG_USE_SSTRIP=y`（已启用）压缩二进制

### Q4: OpenClash 无法启动/核心下载失败
**解决**：
- 确保 `ca-bundle`、`curl`、`ruby` 等依赖已编入固件
- 首次启动需联网下载核心，或预放 `openclash-core` 到 `/etc/openclash/core/`
- 检查系统时间是否正确（NTP 同步）

---

## 🔗 参考资源

| 项目 | 地址 |
|------|------|
| pbs05/ponwrt (上游) | https://github.com/pbs05/ponwrt |
| ztb666ai/ponwrt (分支) | https://github.com/ztb666ai/ponwrt |
| ztb666ai/Actions-OpenWrt-AN758X (CI/CD) | https://github.com/ztb666ai/Actions-OpenWrt-AN758X |
| OpenClash | https://github.com/vernesong/OpenClash |
| ImmortalWrt | https://github.com/immortalwrt/immortalwrt |
| MediaTek mt76 驱动 | https://github.com/openwrt/mt76 |
| Realtek rtw88 驱动 | https://github.com/lwfinger/rtw88 |

---

## 📝 版本记录

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2025-xx-xx | 初始版本：基于 ztb666ai Actions-OpenWrt-AN758X openclash 变体，新增完整 USB 无线驱动栈 |

---

## 💡 后续扩展建议

1. **添加更多 USB 网卡支持**：在 `.config` 中追加 `kmod-rtl8187` (RTL8187L)、`kmod-zd1211rw` (ZD1211) 等
2. **集成 PassWall/MosDNS**：在 `diy-part1-usbwifi.sh` 中设置 `ADD_PASSWALL=true` 或 `ADD_MOSDNS=true`
3. **启用 ccache 加速二次编译**：Workflow 中设置 `USE_CCACHE: true`
4. **多机型矩阵构建**：修改 workflow `strategy.matrix` 同时构建多个 profile
5. **自定义 feeds**：创建 `feeds.conf.custom` 引入私有包源

---

## 📄 许可证

本项目基于 MIT 许可证开源，遵循上游 ponwrt / ImmortalWrt / OpenWrt 许可证。

---

**构建愉快！如有问题请参考上游仓库 Issues 或提交新 Issue。** 🎉