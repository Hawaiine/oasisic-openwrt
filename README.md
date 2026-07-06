# 🏝️ Oasisic OpenWrt

> 自动构建 · 开箱即用 · 专为 PVE 虚拟化优化

[![build](https://github.com/Hawaiine/oasisic-openwrt/actions/workflows/openwrt-auto-build.yml/badge.svg)](https://github.com/Hawaiine/oasisic-openwrt/actions/workflows/openwrt-auto-build.yml)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-25.12.x-00b4ff?logo=openwrt)](https://openwrt.org)
[![Nikki](https://img.shields.io/badge/Nikki-latest-ff6600)](https://github.com/nikkinikki-org/OpenWrt-nikki)
[![PVE](https://img.shields.io/badge/PVE-9.x+-570c2e?logo=proxmox)](https://proxmox.com)
[![License](https://img.shields.io/badge/license-GPLv2-blue)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-x86__64-ff69b4)](https://downloads.openwrt.org/releases/25.12.5/targets/x86/64/)

---

## 📋 项目简介

**Oasisic OpenWrt** 是一套全自动化的 OpenWrt 固件编译系统。每当上游更新时，自动检测并用 **全量 SDK** 编译出带 Nikki 代理、luci-theme-argon 主题、PVE 优化驱动、北京时间时区的专用固件。

```
┌─────────────────────────────────────────────────────┐
│                    🏝️ Oasisic OpenWrt              │
├─────────────────────────────────────────────────────┤
│  📡 自动检测上游 → 全量编译 → 发布 Release          │
│                                                     │
│  ├─ 🔄 OpenWrt 稳定版更新                           │
│  ├─ 🔄 Nikki 新版发布                               │
│  └─ 🔄 Linux LTS 内核更新                           │
│                                                     │
│  🏗️ 编译耗时: 首次 2-4h · 后续 30-60min (ccache)   │
│  📦 产物: squashfs-combined-efi / iso / sha256sums  │
└─────────────────────────────────────────────────────┘
```

---

## ✨ 特性一览

| 类别 | 特性 | 说明 |
|------|------|------|
| 🏗️ **编译方式** | 全量 SDK | 从源码编译全部组件，Nikki 从 feeds 源码集成 |
| 🔄 **自动触发** | 3 源检测 | OpenWrt / Nikki / 内核 LTS，无变化自动跳过 |
| 🛡️ **代理** | Nikki (mihomo) | 最新版，源码编译，无版本滞后问题 |
| 🎨 **主题** | luci-theme-argon | 2.x 最新版 + argon-config 品牌名可配 |
| 🖥️ **PVE 集成** | QEMU Guest Agent | virtio 全系驱动 (net/blk/scsi/rng/serial) |
| 🏠 **网络预设** | 静态 IP | 开箱即用，无需进终端配网络 |
| 🕐 **时区** | 北京时间 CST-8 | 日志、cron、内核 dmesg 全 UTC+8 |
| 📊 **监控** | 硬件看板 | CPU/内存/磁盘/网络仪表盘（statistics） |
| 🔄 **升级** | 在线检测 | luci-app-attendedsysupgrade 一键升级 |
| 🧹 **纯净安全** | 官方源检查 | 仅官方 feeds + Nikki 源，无第三方后门 |

---

## ⚡ 快速开始

### 1️⃣ Fork 仓库

```bash
git clone https://github.com/你的用户名/oasisic-openwrt.git
cd oasisic-openwrt
```

### 2️⃣ 自定义配置

```bash
# 改 IP 地址
vim files/etc/config/network

# 改 root 密码（需要先安装 mkpasswd）
# Ubuntu: sudo apt install whois
mkpasswd -m sha-512 '你的密码'
# 把输出粘到 files/etc/shadow 的 root: 行

# 改品牌名（登录页左上角）
vim files/etc/config/argon-config
```

### 3️⃣ 推送 → 自动构建

```bash
git add -A
git commit -m "✨ init: 初始化自定义配置"
git push origin main
```

GitHub Actions 每天北京时间 14:00 自动检测，也可手动触发。

---

## 📂 项目结构

```
oasisic-openwrt/
│
├── .github/workflows/
│   └── openwrt-auto-build.yml   ← CI/CD 全量编译工作流
│
├── files/                        ← 注入固件的自定义文件
│   └── etc/
│       ├── config/
│       │   ├── network           ← LAN 静态 IP / 网关 / DNS
│       │   ├── system            ← 时区 CST-8 / NTP 服务器
│       │   ├── luci              ← 语言 zh-cn / 主题 argon
│       │   └── argon-config      ← 品牌名 / 背景模糊
│       ├── shadow                ← root 密码（默认: Oasisic@2025）
│       ├── uci-defaults/
│       │   └── 99-custom         ← 首次启动脚本（自配置后自毁）
│       └── banner                ← SSH 登录欢迎画
│
├── scripts/
│   └── gen-config.sh             ← 生成 .config（184 行包配置）
│
├── feeds.conf                    ← 源码源列表（含 nikki 源）
├── config.buildinfo              ← 完整 .config 参考
└── last_build_version            ← CI 版本缓存（自动维护）
```

---

## 🏗️ 编译流程详解

### 工作流流水线

```
┌─────────────┐
│ 检测上游更新  │  ← 每天 UTC 06:00 / 北京时间 14:00
└──────┬──────┘
       │ 有更新?
       ├── No  → ⏭️ 跳过，0 成本退出
       │
       └── Yes → ┌───────────────────────┐
                  │ 全量 SDK 编译          │
                  │                       │
                  │ 1. 安装依赖            │
                  │ 2. 恢复 ccache 缓存    │ ← 二次起加速 ~60%
                  │ 3. 恢复源码树缓存       │ ← 跳过 git clone
                  │ 4. 恢复 dl 包缓存       │ ← 跳过下载
                  │ 5. git clone 源码      │
                  │ 6. cp files/ 注入配置   │
                  │ 7. feeds update -a     │ ← 含 Nikki 源
                  │ 8. feeds install -a    │
                  │ 9. make defconfig      │
                  │ 10. make download      │
                  │ 11. make -j$(nproc)    │ ← 核心编译
                  │ 12. 上传 Artifact      │
                  │ 13. 发布 Release       │
                  └───────────────────────┘
```

### 缓存策略

| 缓存类型 | 缓存路径 | 缓存 Key | 命中后节省 |
|----------|----------|----------|-----------|
| 🔧 ccache | `/tmp/.ccache` | 版本号 + config hash | 减少重复编译 ~60% |
| 📦 源码树 | `openwrt/` | 版本号 | 跳过 git clone (1GB+) |
| 📥 dl 包 | `openwrt/dl/` + `feeds/` | 版本号 + config hash | 跳过下载 (数百 MB) |

---

## 📦 预装包清单

### 核心系统

| 包名 | 说明 |
|------|------|
| `base-files` | 系统基础文件 |
| `busybox` | 命令行工具集 |
| `dnsmasq-full` | DNS/DHCP 服务器（全功能版） |
| `firewall4` | nftables 防火墙 |
| `dropbear` | SSH 服务器 |
| `luci` | Web 管理界面 |
| `nftables` | 防火墙规则引擎 |
| `procd` | 进程管理 / 启动服务 |
| `qemu-ga` | PVE QEMU Guest Agent |

### 代理网络 🌐

| 包名 | 说明 |
|------|------|
| `nikki` | Nikki 代理主程序 |
| `mihomo-meta` | mihomo 内核 |
| `luci-app-nikki` | Nikki 网页管理面板 |
| `kmod-tun` | TUN 虚拟网卡 |
| `kmod-nf-tproxy` | TPROXY 透明代理 |
| `kmod-nft-tproxy` | nftables TPROXY 支持 |
| `yq` | YAML 解析器（处理 Nikki 配置） |

### 主题美化 🎨

| 包名 | 说明 |
|------|------|
| `luci-theme-argon` | Argon 主题 |
| `luci-app-argon-config` | 主题配置面板 |
| `luci-i18n-*-zh-cn` | 全中文翻译包 |
| `luci-compat` | 主题兼容层 |

### PVE 集成 🖥️

| 包名 | 说明 |
|------|------|
| `qemu-ga` | QEMU Guest Agent |
| `kmod-virtio-net` | 半虚拟化网卡 |
| `kmod-virtio-blk` | 半虚拟化磁盘 |
| `kmod-virtio-scsi` | SCSI 半虚拟化 |
| `kmod-virtio-rng` | 虚拟随机数生成器 |
| `kmod-virtio-serial` | 虚拟串口（qemu-ga 依赖） |

### 常用工具 🔧

| 包名 | 说明 |
|------|------|
| `bash` | Bash shell |
| `curl` / `wget-ssl` | HTTP 下载 |
| `htop` | 进程管理器 |
| `iperf3` | 网络测速 |
| `tcpdump` | 抓包工具 |
| `vim-full` | 文本编辑器 |
| `lm-sensors` | 硬件传感器 |
| `openssl-util` | SSL 工具 |

---

## 📥 PVE 导入指南

### 创建虚拟机

```bash
# 1. 从 Release 下载 squashfs-combined-efi.img.gz
# 2. 解压到 PVE 节点
gunzip openwrt-*-x86-64-generic-squashfs-combined-efi.img.gz

# 3. 创建 VM（无磁盘）
qm create 100 \
  --name "Oasisic-OpenWrt" \
  --ostype l26 \
  --machine q35 \
  --bios ovmf \
  --cores 2 \
  --memory 1024 \
  --net0 virtio,bridge=vmbr0

# 4. 导入磁盘
qm importdisk 100 openwrt-*-x86-64-generic-squashfs-combined-efi.img local-lvm

# 5. 挂载磁盘到 VM
qm set 100 --scsihw virtio-scsi-single \
  --scsi0 local-lvm:vm-100-disk-0

# 6. 设置启动顺序
qm set 100 --boot order=scsi0

# 7. 启用 QEMU Guest Agent
qm set 100 --agent enabled=1

# 8. 启动
qm start 100
```

### 网络拓扑建议

```
         ┌──────────┐
         │  RouterOS │  ← 主路由（网关: 10.10.10.253）
         │  拨号上网  │
         └────┬─────┘
              │
         ┌────▼─────┐
         │ Oasisic  │  ← 旁路网关 (10.10.10.252)
         │  OpenWrt │     Nikki 代理 + dnsmasq
         └────┬─────┘
              │
         ┌────▼─────┐
         │  内网设备  │  ← 网关指向 10.10.10.252
         └──────────┘
```

---

## 🔄 触发策略

| 触发源 | 检测端点 | 频率 | 更新后 |
|--------|----------|------|--------|
| OpenWrt 稳定版 | `api.github.com/repos/openwrt/openwrt/releases/latest` | 每日 | 全量编译 |
| Nikki 新版 | `api.github.com/repos/nikkinikki-org/OpenWrt-nikki/releases/latest` | 每日 | 全量编译 |
| Linux LTS 内核 | `www.kernel.org/releases.json` | 每日 | 全量编译 |
| 手动触发 | GitHub Actions 按钮 | 随时 | 立即编译 |

版本无变化时自动跳过，0 成本退出。

---

## 🛡️ 安全机制

| 维度 | 措施 |
|------|------|
| 📡 源码源 | 仅 `github.com/openwrt/openwrt` 官方库 |
| 📦 feeds | 仅官方源：packages / luci / routing / telephony / video + Nikki |
| 🔐 Nikki 源 | `github.com/nikkinikki-org/OpenWrt-nikki`（官方库） |
| 🧬 包声明 | `gen-config.sh` 中显式声明所有包，无隐藏依赖 |
| 🧹 首次启动 | `uci-defaults/99-custom` 执行后自毁 |
| 🔒 密码 | 默认密码 `Oasisic@2025`，首次登录后请修改 |
| 🚫 无后门 | 不包含任何第三方源、闭源驱动、遥测脚本 |

---

## ❓ FAQ

### Q: 首次编译要多久？会不会超时？

A: 首次全量编译约 2-4 小时。GitHub Actions 免费版有 6 小时限额，完全够用。后续编译有 ccache 缓存，约 30-60 分钟。

### Q: 磁盘空间够吗？

A: GitHub Actions 免费提供 14GB 磁盘。全量 SDK 编译峰值约 8-10GB，够用但不算宽裕。如果磁盘不够，可以手动清理 `build_dir/` 和 `staging_dir/` 中间产物。

### Q: 怎么改 IP 地址？

A: 修改 `files/etc/config/network` 中的 `option ipaddr`、`option gateway`、`list dns` 行，然后推送触发重新编译。

### Q: 怎么改登录页左上角名字？

A: 修改 `files/etc/config/argon-config` 中的 `option brand` 行，例如 `option brand '我的路由器'`。

### Q: 编译好后怎么在 PVE 里导入？

A: 参考上方「📥 PVE 导入指南」章节。核心步骤：解压 → qm importdisk → 设置启动顺序 → 启用 QEMU GA。

### Q: 自定义包怎么加？

A: 修改 `scripts/gen-config.sh`，在对应分类下加 `CONFIG_PACKAGE_xxx=y` 行，然后推送触发重新编译。

### Q: 不想用 Nikki 了怎么办？

A: 注释掉 `gen-config.sh` 中所有 `CONFIG_PACKAGE_nikki*`、`CONFIG_PACKAGE_mihomo-meta*` 相关行，以及 `feeds.conf` 中的 nikki 行。

---

## 🧰 开发参考

### 本地测试编译

```bash
# 需要 Linux 环境，推荐 Ubuntu 22.04+
sudo apt install build-essential libncurses5-dev libncursesw5-dev \
  zlib1g-dev gawk git gettext wget unzip python3 file qemu-utils ccache

git clone --depth 1 --branch v25.12.5 https://github.com/openwrt/openwrt.git
cd openwrt
cp /path/to/feeds.conf feeds.conf.default
cp /path/to/files/ files/
cp /path/to/.config .config

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make download -j$(nproc)
make -j$(nproc) V=s
```

### 验证编译产物

```bash
# 检查镜像完整性
cd openwrt/bin/targets/x86/64/
sha256sum -c sha256sums 2>/dev/null | grep OK

# 列出固件信息
ls -lh *.gz *.iso
```

---

## 📌 相关项目

| 项目 | 说明 |
|------|------|
| 🏝️ [Oasisic-Icons](https://github.com/Hawaiine/Oasisic-Icons) | 代理图标库（427 图标） |
| 🛡️ [mihomo-rules](https://github.com/Hawaiine/mihomo-rules) | mihomo 规则集（105 品牌） |
| 📺 [iptv-sources](https://github.com/Hawaiine/iptv-sources) | IPTV 直播源聚合 |
| 🎬 [moviepilot-category](https://github.com/Hawaiine/moviepilot-category) | MoviePilot 二级分类策略 |

---

## 📜 许可证

[GNU General Public License v2](LICENSE) — 与 OpenWrt 项目保持一致。

---

> 🏝️ **Oasisic OpenWrt** — 自动构建 · 开箱即用 · 专为虚拟化优化