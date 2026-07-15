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

**Oasisic OpenWrt** 是一套全自动化的 OpenWrt 固件编译系统。每当上游更新时，自动检测并编译出带 Nikki 代理、bootstrap 主题、PVE 优化驱动的专用固件。

| | |
|---|---|
| 🏝️ **项目** | **Oasisic OpenWrt** |
| 📡 **流程** | 检测上游 → 全量编译 → Release |
| 🎯 **触发源** | OpenWrt / Nikki |
| ⏱ **耗时** | ~77min · 增量 ~30min（三层缓存） |
| 📦 **产物** | 固件 · sha256sums · feeds.conf |

---

## ✨ 特性一览

| 类别 | 特性 | 说明 |
|------|------|------|
| 🏗️ **编译方式** | 全量 SDK | 从源码编译全部组件，Nikki 从 feeds 源码集成 |
| 🔄 **自动触发** | 2 源检测 | OpenWrt / Nikki 自动检测新 tag |
| 🛡️ **代理** | Nikki (mihomo) | 自动检测最新版，旁路网关模式 |
| 🖥️ **PVE 集成** | QEMU Guest Agent | virtio 全系驱动 (net/blk/scsi/rng/serial) |
| 🏠 **网络预设** | DHCP 客户端 | 首次开机自动获取 IP，无硬编码 IP |
| 🕐 **时区** | 北京时间 CST-8 | 日志、cron 全 UTC+8 |
| 🧹 **纯净安全** | 官方源检查 | 仅官方 feeds + Nikki，GitHub 镜像锁定分支 |
| 🔐 **ucode** | LuCI 基础依赖 | 修复 LuCI CGI 403 |
| 📦 **Feeds** | GitHub 镜像 | 锁定 openwrt-25.12 分支，国内连通性优化 |
| 🧭 **设置向导** | 首次启动 | 纯 HTML/CSS/JS 向导，零外部依赖 |
| 🧪 **烟雾测试** | QEMU | 固件构建后自动启动验证 LuCI |
| 🔏 **签名验证** | minisign | 固件完整性签名 + 用户验证指南 |
| 🧹 **自动清理** | Actions 缓存 | 每 3 天清理失败运行 + 过期缓存 |

---

## 🧭 设置向导（首次启动）

首次开机自动进入设置向导，引导用户配置网络和密码。

### 流程

```
开机 → uci-defaults 创建 .oasisic-firstboot 标记
     → 访问 IP → index.html 检测标记
     → 有标记 → 跳转 setup.html 设置向导
     → 用户完成配置 → CGI 写入配置 + 清除标记 + 重启 uhttpd
     → 下次访问 → 跳转 LuCI 管理界面
```

### 文件结构

| 文件 | 说明 |
|------|------|
| `files/www/index.html` | 入口页，检测首次启动标记 |
| `files/www/setup.html` | 设置向导页面（混搭光暗主题，781 行） |
| `files/www/cgi-bin/setup` | CGI 后端，接收 JSON 写 uci 配置 |
| `files/www/cgi-bin/check-firstboot` | CGI 检测接口 |
| `files/etc/uci-defaults/99-custom` | 首次启动创建标记 |
| `files/usr/lib/oasisic/firstboot.sh` | 首次启动状态机共享库 |

### 安全设计

- 零外部依赖（无 CDN 字体/图标/JS 库）
- 首次启动标记 `/etc/.oasisic-firstboot` 控制访问
- 设置完成后 CGI 自禁用（chmod 000）
- IPv4 格式校验 + 端口范围校验 + 密码一致性校验
- 跳过模式：只清标记不改配置

---

## 🏗️ 编译流程

### 构建流水线

```
check-upstream
  │
  ├── ⏭️ 版本无变化 → 跳过
  │
  └── ✅ 检测到更新 → build job
        │
        ├── 💾 释放 runner 磁盘空间
        ├── 📦 安装依赖
        ├── 💾 恢复三层缓存（ccache + 源码树 + dl）
        ├── ⬇️ 克隆源码（自动重试）
        ├── 🔑 生成随机 root 密码
        ├── ⚙️ 复制自定义文件 + 版本注入
        ├── ⚙️ 配置 feeds（版本跟踪 + 自动重试）
        ├── ⚙️ gen-config.sh → make defconfig
        ├── ⬇️ make download（自动重试）
        ├── 🏗️ 编译（失败时自动 verbose 重跑）
        ├── 📊 ccache 统计
        ├── 🔏 minisign 签名
        ├── 📋 check-firmware.sh 自检
        └── 📤 上传 Artifact
              │
              ▼
        qemu-smoke-test（阻断门）
              │
              ├── ❌ QEMU 启动失败 → 终止
              │
              └── ✅ LuCI 响应 200 → release job
                    │
                    ├── 🚀 发布 GitHub Release（含随机密码）
                    └── 📢 Discord 通知
```

### 三层缓存策略

| 缓存 | 缓存路径 | Key 策略 |
|------|----------|----------|
| 🔧 ccache | `/tmp/.ccache` | `ccache-openwrt-{ver}-{config_hash}` |
| 📦 源码树 | `openwrt/` | `source-openwrt-{ver}-{config_hash}` |
| 📥 dl 包 | `openwrt/dl/` + `feeds/` | `dl-openwrt-{ver}-{config_hash}` |

---

## 📂 项目结构

```
oasisic-openwrt/
│
├── .github/
│   ├── workflows/
│   │   ├── openwrt-auto-build.yml   ← CI/CD 自动化编译工作流
│   │   └── cleanup-actions.yml      ← 定时清理失败运行 + 缓存
│   └── minisign.pub                 ← 固件签名公钥
│
├── files/                        ← 注入固件的自定义文件
│   └── etc/
│       ├── config/
│       │   ├── network           ← LAN DHCP（首次开机自动获取 IP）
│       │   ├── firewall          ← 旁路网关全 ACCEPT 规则
│       │   ├── system            ← hostname / NTP / 时区
│       │   └── dhcp              ← dnsmasq + IPv6 中继
│       ├── banner                ← OpenWrt 官方 logo + Oasisic 品牌
│       └── uci-defaults/
│           └── 99-custom         ← 首次启动配置脚本
│
├── scripts/
│   ├── gen-config.sh             ← 包配置生成器（明确声明所有包）
│   ├── gen-feeds-conf.sh         ← 动态 feeds.conf 生成器
│   ├── check-firmware.sh         ← 固件完整性自检
│   └── notify-discord.py         ← Discord 通知
│
├── feeds.conf                    ← 官方 GitHub 镜像 + 分支锁定
├── last_build_version            ← 上次构建的版本标识
└── README.md                     ← 本文档
```

---

## 🚀 快速开始

### 1️⃣ Fork 此仓库

### 2️⃣ 配置 GitHub Secrets

| Secret | 用途 |
|--------|------|
| `DISCORD_BOT_TOKEN` | Discord 通知机器人 Token |

### 3️⃣ 推送 → 自动构建

```bash
git add -A
git commit -m "✨ init: 初始化自定义配置"
git push origin main
```

GitHub Actions 每天北京时间 14:00 自动检测上游。也可手动触发。

### 4️⃣ PVE 导入

```bash
# 从 Release 下载 squashfs-combined-efi.img.gz → 解压
gunzip openwrt-x86-64-generic-squashfs-combined-efi.img.gz

# PVE 创建 VM → 导入磁盘
qm create 100 --name "Oasisic-OpenWrt" --ostype l26 \
  --machine q35 --bios ovmf --cores 2 --memory 1024 \
  --net0 virtio,bridge=vmbr0

qm importdisk 100 openwrt-x86-64-generic-squashfs-combined-efi.img local-lvm
qm set 100 --scsihw virtio-scsi-single --scsi0 local-lvm:vm-100-disk-0
qm set 100 --boot order=scsi0 --agent enabled=1
qm start 100
```

> ⚠️ **首次开机注意事项：** 固件默认 DHCP 客户端模式。启动后到主路由 DHCP 列表中查找主机名 `Oasisic-OpenWrt`。

---

## 🛡️ 安全机制

| 维度 | 措施 |
|------|------|
| 📡 源码源 | 仅 `github.com/openwrt/openwrt` 官方库 |
| 📦 feeds | 官方 GitHub 镜像，锁定 openwrt-25.12 分支 |
| 🔐 Nikki | `github.com/nikkinikki-org/OpenWrt-nikki` |
| 🧬 包声明 | `gen-config.sh` 显式声明所有包，无隐藏依赖 |
| 🧹 首次启动 | `uci-defaults/99-custom` 执行后自毁 |
| 🚫 无后门 | 不包含任何第三方源、闭源驱动、遥测脚本 |

---

## 🔧 排错指南

### 编译失败常见原因

| 症状 | 原因 | 解决 |
|------|------|------|
| `make download` 失败 | 缺少 `genisoimage` | 确保 workflow 安装 `genisoimage` |
| Release 失败 `Resource not accessible` | 缺少权限 | 添加 `permissions: contents: write` |
| 缓存不命中 | key 设计错误 | 用版本号代替 `run_id` |
| LuCI 无限转圈 | 缺少 ucode base 包 | 确保 `CONFIG_PACKAGE_ucode=y` |
| Feeds 更新失败 | 分支名语法错误 | 25.12 用 `;` 而非 `^` |

### 编译时间参考

| 场景 | 首次 (cold) | 二次+ (ccache+缓存命中) |
|------|:-----------:|:----------------------:|
| 全量 SDK | ~77min | ~30-45min |

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