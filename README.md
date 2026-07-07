# 🏝️ Oasisic OpenWrt

> 全自动 OpenWrt 固件构建 · 源码编译 Nikki · PVE 开箱即用

[![build](https://github.com/Hawaiine/oasisic-openwrt/actions/workflows/openwrt-auto-build.yml/badge.svg)](https://github.com/Hawaiine/oasisic-openwrt/actions/workflows/openwrt-auto-build.yml)
[![OpenWrt](https://img.shields.io/github/v/release/openwrt/openwrt?logo=openwrt&label=OpenWrt&color=00b4ff)](https://openwrt.org)
[![Nikki](https://img.shields.io/github/v/release/nikkinikki-org/OpenWrt-nikki?logo=go&label=Nikki&color=ff6600)](https://github.com/nikkinikki-org/OpenWrt-nikki)
[![PVE](https://img.shields.io/badge/PVE-ready-570c2e?logo=proxmox)](https://proxmox.com)
[![License](https://img.shields.io/badge/license-GPLv2-blue)](LICENSE)
[![Platform](https://img.shields.io/badge/x86__64-squashfs-ff69b4)](https://downloads.openwrt.org/releases/targets/x86/64/)

---

## 📋 项目简介

**Oasisic OpenWrt** 是一套全自动化的 OpenWrt 固件编译系统。每当上游更新时，自动检测并用 **全量 SDK** 编译出带 Nikki 代理、luci-theme-argon 主题、PVE 优化驱动、北京时间时区的专用固件。

```text
╔═══════════════════════════════════════════════╗
║              🏝️ Oasisic OpenWrt               ║
╠═══════════════════════════════════════════════╣
║                                               ║
║  📡 检测上游 → 🏗️ 全量编译 → 🚀 Release     ║
║                                               ║
║  触发源: OpenWrt / Nikki / Linux LTS          ║
║                                               ║
║  ⏱  ~90min · 增量 ~30min (三层缓存)          ║
║  📦  固件 · sha256sums · feeds.conf           ║
║                                               ║
╚═══════════════════════════════════════════════╝
```

---

## ✨ 特性一览

| 类别 | 特性 | 说明 |
|------|------|------|
| 🏗️ **编译方式** | 全量 SDK | 从源码编译全部组件，Nikki 从 feeds 源码集成 |
| 🔄 **自动触发** | 3 源检测 | OpenWrt / Nikki / 内核 LTS，无变化自动跳过 |
| 🛡️ **代理** | Nikki (mihomo) | 最新版，源码编译，无版本滞后问题 |
| 🎨 **主题** | luci-theme-argon | 2.x + argon-config，品牌名可配 |
| 🖥️ **PVE 集成** | QEMU Guest Agent | virtio 全系驱动 (net/blk/scsi/rng/serial) |
| 🏠 **网络预设** | 静态 IP 10.10.10.252/24 | 开箱即用 |
| 🕐 **时区** | 北京时间 CST-8 | 日志、cron 全 UTC+8 |
| 📊 **监控** | 硬件看板 | statistics 仪表盘 |
| 🔄 **升级** | 在线检测 | luci-app-attendedsysupgrade |
| 🧹 **纯净安全** | 官方源检查 | 仅官方 feeds + Nikki 源 |

---

## 🏗️ 编译流程

### 构建流水线

```
check-upstream
  │
  ├── ⏭️ 版本无变化 → 跳过，0 成本退出
  │
  └── ✅ 检测到更新 → build job
        │
        ├── 📦 安装依赖 (build-essential, gawk, ccache, genisoimage...)
        ├── 💾 恢复 ccache 缓存       ← key: ccache-openwrt-{ver}-{config_hash}
        ├── 💾 恢复源码树缓存          ← key: source-openwrt-{ver}-{config_hash}
        ├── 💾 恢复 dl 缓存           ← key: dl-openwrt-{ver}-{config_hash}
        │
        ├── ⬇️ 克隆 OpenWrt 源码      ← 缓存未命中时执行
        ├── ⚙️ cp files/ 注入配置
        ├── ⚙️ feeds update -a        ← 含 nikki 源
        │    ├── packages / luci / routing / telephony / video
        │    └── nikki ✅
        ├── ⚙️ make defconfig
        ├── ⬇️ make download
        ├── 🏗️ make -j4 V=s            ← 核心编译 (1-4h)
        ├── 🧹 清理 build_dir         ← 省磁盘
        ├── 📋 展示产物清单
        ├── 💾 保存版本标识
        ├── 📤 上传 Artifact
        └── 🚀 发布 Release
```

### 三层缓存策略

| 缓存 | 缓存路径 | Key 策略 | 命中后效果 |
|------|----------|----------|-----------|
| 🔧 ccache | `/tmp/.ccache` | `ccache-openwrt-{ver}-{config_hash}` | 减少重复编译 ~60% |
| 📦 源码树 | `openwrt/` | `source-openwrt-{ver}-{config_hash}` | 跳过 git clone (1GB+) |
| 📥 dl 包 | `openwrt/dl/` + `feeds/` | `dl-openwrt-{ver}-{config_hash}` | 跳过下载 (数百 MB) |

---

## 📂 项目结构

```
oasisic-openwrt/
│
├── .github/workflows/
│   └── openwrt-auto-build.yml   ← CI/CD 全量编译工作流 (260+ 行)
│
├── files/                        ← 注入固件的自定义文件
│   └── etc/
│       ├── config/
│       │   ├── network           ← LAN 10.10.10.252/24
│       │   ├── system            ← CST-8 / 4 个 NTP
│       │   ├── luci              ← zh-cn / argon
│       │   └── argon-config      ← 品牌名
│       ├── shadow                ← root 默认密码 Oasisic@2025
│       ├── uci-defaults/
│       │   └── 99-custom         ← 首次启动脚本 → 自毁
│       └── banner                ← SSH 欢迎画
│
├── scripts/
│   └── gen-config.sh             ← 生成 .config (184 行包配置)
│
├── feeds.conf                    ← 源码源（含 nikki）
└── last_build_version            ← CI 版本缓存
```

---

## Release 产物清单

每次构建成功后 Release 包含：

```
📦 oasisic-openwrt-25.12.5 Release
│
├── 📄 固件镜像
│   ├── openwrt-x86-64-generic-squashfs-combined-efi.img.gz   ← PVE EFI 启动 (推荐)
│   ├── openwrt-x86-64-generic-squashfs-combined.img.gz       ← BIOS 启动
│   ├── openwrt-x86-64-generic-image-efi.iso                  ← EFI ISO
│   └── openwrt-x86-64-generic-image.iso                      ← BIOS ISO
│
├── 📄 sha256sums                     ← 固件校验和
└── 📄 feeds.conf.default             ← 编译使用的源列表
```

---

## ⚡ 快速开始

### 1️⃣ Fork 仓库

```bash
git clone https://github.com/你的用户名/oasisic-openwrt.git
cd oasisic-openwrt
```

### 2️⃣ 自定义配置

```bash
# 改 IP 地址 (默认 10.10.10.252)
vim files/etc/config/network

# 改 root 密码
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

GitHub Actions 每天北京时间 14:00 自动检测。也可手动触发：**Actions → openwrt-auto-build → Run workflow**。

### 4️⃣ PVE 导入

```bash
# 从 Release 下载 squashfs-combined-efi.img.gz → 解压
gunzip openwrt-*-squashfs-combined-efi.img.gz

# PVE 创建 VM → 导入磁盘
qm create 100 --name "Oasisic-OpenWrt" --ostype l26 \
  --machine q35 --bios ovmf --cores 2 --memory 1024 \
  --net0 virtio,bridge=vmbr0

qm importdisk 100 openwrt-*-squashfs-combined-efi.img local-lvm
qm set 100 --scsihw virtio-scsi-single --scsi0 local-lvm:vm-100-disk-0
qm set 100 --boot order=scsi0 --agent enabled=1
qm start 100
```

---

## 🛡️ 安全机制

| 维度 | 措施 |
|------|------|
| 📡 源码源 | 仅 `github.com/openwrt/openwrt` 官方库 |
| 📦 feeds | 官方源: packages / luci / routing / telephony / video + Nikki |
| 🔐 Nikki | `github.com/nikkinikki-org/OpenWrt-nikki` |
| 🧬 包声明 | `gen-config.sh` 显式声明所有包，无隐藏依赖 |
| 🧹 首次启动 | `uci-defaults/99-custom` 执行后自毁 |
| 🔒 密码 | 预置 hash，首次登录后请修改 |
| 🚫 无后门 | 不包含任何第三方源、闭源驱动、遥测脚本 |

---

## 🔧 排错指南

### 编译失败常见原因

| 症状 | 原因 | 解决 |
|------|------|------|
| `make download` 失败 | 缺少 `mkisofs` | 确保 workflow 安装 `genisoimage` |
| Release 失败 `Resource not accessible` | 缺少 `contents: write` 权限 | 在 workflow 添加 `permissions: contents: write` |
| `make` 只跑了几秒 | `2>&1 | tail -30` 管道截断 | 移除 `| tail`，直接 `make -j4 V=s` |
| 缓存不命中 | `run_id` 导致 key 每次都变 | 用版本号代替 `run_id` |
| Node.js 20 deprecation | action 版本太旧 | 升级到 `cache@v5`, `upload-artifact@v7`, `action-gh-release@v3` |

### 编译时间参考

| 场景 | 首次 | 二次 (ccache+源码缓存) | 三次+ (全部命中) |
|------|:----:|:--------------------:|:---------------:|
| 全量 SDK | 2-4h | 30-60min | 30-60min |

### 常见问题

**Q: 怎么改成我的 IP？**
A: 改 `files/etc/config/network` 里的 `option ipaddr`、`option gateway`、`list dns`，推送触发重新编译。

**Q: 怎么加包？**
A: 在 `scripts/gen-config.sh` 对应分类下加 `CONFIG_PACKAGE_xxx=y`。

**Q: 固件刷了进不去管理界面？**
A: 确认 PVE 网桥模式：VM 要用 `virtio` 网卡，并确认 `files/etc/config/network` 里的 `device` 名称匹配。

**Q: IPK 包怎么单独安装？**
A: IPK 包在 Actions 构建 Artifact 中可下载，解压后 `opkg install *.ipk` 即可，无需重新编译整套固件。

---

## 📌 相关项目

| 项目 | 说明 |
|------|------|
| 🏝️ [Oasisic-Icons](https://github.com/Hawaiine/Oasisic-Icons) | 代理图标库 (427 图标) |
| 🛡️ [mihomo-rules](https://github.com/Hawaiine/mihomo-rules) | mihomo 规则集 (105 品牌) |
| 📺 [iptv-sources](https://github.com/Hawaiine/iptv-sources) | IPTV 直播源聚合 |
| 🎬 [moviepilot-category](https://github.com/Hawaiine/moviepilot-category) | MoviePilot 二级分类策略 |

---

## 📜 许可证

[GNU General Public License v2](LICENSE) — 与 OpenWrt 项目保持一致。

---

> 🏝️ **Oasisic OpenWrt** — 自动构建 · 开箱即用 · 专为虚拟化优化