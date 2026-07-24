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
| 🎯 **触发源** | OpenWrt Tag + Nikki 引用（Tag / 分支 / Commit） |
| ⏱ **耗时** | ~77min · 增量 ~30min（三层缓存） |
| 📦 **产物** | 固件 · sha256sums · feeds.conf |

---

## ✨ 特性一览

| 类别 | 特性 | 说明 |
|------|------|------|
| 🏗️ **编译方式** | 全量 SDK | 从源码编译全部组件，Nikki 从 feeds 源码集成 |
| 🔄 **自动触发** | 2 源检测 | OpenWrt Tag + Nikki 引用（Tag / 分支 / Commit） |
| 🛡️ **代理** | Nikki (mihomo) | 自动检测最新版，旁路网关模式 |
| 🖥️ **PVE 集成** | QEMU Guest Agent | virtio 全系驱动 (net/blk/scsi/rng/serial) |
| 🏠 **网络预设** | DHCP 客户端 | 首次开机自动获取 IP，无硬编码 IP |
| 🕐 **时区** | 北京时间 CST-8 | 日志、cron 全 UTC+8 |
| 🧹 **纯净安全** | 官方源检查 | 仅官方 feeds + Nikki，GitHub 镜像锁定分支 |
| 🔐 **ucode** | LuCI 基础依赖 | 修复 LuCI CGI 403 |
| 📦 **Feeds** | GitHub 镜像 | 锁定 openwrt-25.12 分支，Nikki 引用支持 Tag/分支/Commit |
| 🧭 **设置向导** | 首次启动 | 纯 HTML/CSS/JS 向导，零外部依赖 |
| 🧪 **烟雾测试** | QEMU | 固件构建后自动启动验证 LuCI |
| 🔏 **签名验证** | minisign | 固件完整性签名 + 用户验证指南 |
| 🧹 **自动清理** | Actions 缓存 | 每 3 天清理失败运行 + 过期缓存 |
| 🌐 **诊断默认** | DNSPod | 网络诊断默认地址 `119.29.29.29`（国内解析快、稳定） |
| 🈴 **语言修复** | `zh_cn` 下划线 | 修复 `luci.languages` 在全新固件上不存在的问题，自动注册中文 |

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
| `files/etc/uci-defaults/99-custom` | 首次启动配置脚本（语言注册/诊断地址/网络预设） |
| `files/usr/lib/oasisic/firstboot.sh` | 首次启动状态机共享库 |

### 安全设计

- 零外部依赖（无 CDN 字体/图标/JS 库）
- 首次启动标记 `/etc/.oasisic-firstboot` 控制访问
- 设置完成后 CGI 自禁用（chmod 000）
- IPv4 格式校验 + 端口范围校验 + 密码一致性校验
- 跳过模式：只清标记不改配置

### 99-custom 脚本详解

首次启动脚本 `files/etc/uci-defaults/99-custom` 负责设置语言、诊断地址、网络默认值等，执行后自毁。

#### LuCI 语言注册（关键修复 ✅ 已通过构建 #95 验证）

```sh
uci set luci.languages='internal'
uci set luci.languages.zh_cn='简体中文 (Simplified Chinese)'
uci set luci.main.lang='zh_cn'
```

**为什么用 `zh_cn`（下划线）？**

- `luci.mk` 的 `LuciTranslation` 宏通过 `$(subst -,\\\_,zh-cn)` 生成的就是 `zh_cn`
- LuCI dispatcher 把 `_` 替换成 `-` 再去匹配翻译文件 `base.zh-cn.lmo`
- 全新固件上 `luci.languages` 配置段不存在，**必须手动创建**（`uci set luci.languages='internal'`）
- apk 包自带的 uci-defaults 注册脚本因 [openwrt#16987](https://bugs.openwrt.org/index.php?do=details&task_id=16987) 在 QEMU 环境中不执行

#### 网络诊断默认地址

```sh
uci set luci.diag.dns='119.29.29.29'
uci set luci.diag.ping='119.29.29.29'
uci set luci.diag.route='119.29.29.29'
```

DNSPod `119.29.29.29` 国内解析快、稳定，替换默认的 Google DNS。

#### 清理项

- 移除 `uci set luci.title.title='Oasisic OpenWrt'`——经查 `openwrt/luci` 全量源码，无任何代码读取此配置项，属于无效定制
- hostname 由 `files/etc/config/system` 静态写入 `option hostname 'Oasisic-OpenWrt'`，开机直接生效，无需在 99-custom 中重复设置

---

## 🏗️ 编译流程

### 构建流水线（5 站式多阶段）

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
        ├── 🔑 生成随机 root 密码（SHA-512 + 注释清理 + 写入校验）
        ├── ⚙️ 复制自定义文件 + 版本注入
        ├── ⚙️ 配置 feeds（版本跟踪 + 自动重试）
        ├── ⚙️ gen-config.sh → make defconfig
        ├── ⬇️ make download（自动重试）
        ├── 🏗️ 编译（失败时自动 verbose 重跑）
        ├── 📊 ccache 统计（中英双语）
        ├── 🔏 minisign 签名
        ├── 📋 check-firmware.sh 自检
        ├── 💾 保存版本标识
        ├── 📤 上传 Artifact → 独立阻断门
              │
              ▼
        qemu-smoke-test job（独立阻断门）
          │
          ├── ❌ QEMU 启动失败 → 终止
          │
          └── ✅ LuCI 响应 200 → release job
                │
                ├── 🚀 发布 GitHub Release（含随机密码）
                ├── 📢 Discord 通知
                └── 🖊️ persist-last-build job（回写版本标识）
```

### 三层缓存策略

| 缓存 | 缓存路径 | Key 策略 |
|------|----------|----------|
| 🔧 ccache | `/tmp/.ccache` | `ccache-openwrt-{ver}-{config_hash}` |
| 📦 源码树 | `openwrt/` | `source-openwrt-{ver}-{config_hash}` |
| 📥 dl 包 | `openwrt/dl/` + `feeds/` | `dl-openwrt-{ver}-{nikki_sha}-{config_hash}` |

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
│       │       ├── system            ← hostname / NTP / 时区（use_dhcp 默认关闭）
│       │   └── dhcp              ← dnsmasq + IPv6 中继
│       ├── banner                ← OpenWrt 官方默认
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
├── last_build_version            ← 上次构建的版本标识（成功构建后由 CI 回写，受版本控制）
└── README.md                     ← 本文档
```

---

## 🚀 快速开始

### 1️⃣ Fork 此仓库

### 2️⃣ 配置 GitHub Secrets

| Secret | 用途 |
|--------|------|
| `DISCORD_BOT_TOKEN` | Discord 通知机器人 Token |
| `MINISIGN_SECRET_KEY` | minisign 签名私钥（十六进制） |
| `MINISIGN_KEY_ID` | minisign 密钥 ID（十六进制，8 字节） |
| `MINISIGN_PASSWORD` | minisign 私钥密码 |

### 3️⃣ 推送 → 自动构建

```bash
git add .github/workflows/ scripts/ feeds.conf .gitignore LICENSE README.md
git commit -m "✨ init: 初始化自定义配置"
git push origin main
```

GitHub Actions 每天北京时间 14:00 自动检测上游。也可手动触发。

### 手动构建（workflow_dispatch）

#### 用途

手动构建适用于以下场景：
- 需要立即验证某个 Nikki 分支或特定提交的固件，不等待定时检测
- 定时任务默认跟随 Nikki 最新正式版 Release Tag，仅有新 Commit 但未发布 Tag 时不会自动触发

手动构建与定时任务并行存在，不是二选一的关系。

#### 参数说明

| 参数 | 类型 | 默认值 | 含义 | 填写示例 |
|------|------|--------|------|---------|
| `force_build` | 布尔 | `false` | 是否跳过版本比对、强制进入完整编译 | `true` / `false` |
| `nikki_ref` | 字符串 | 空 | Nikki 代码引用。留空表示使用最新正式版 Tag；可填写 Tag 名、分支名、完整或短 Commit SHA | 见下文 |

#### nikki_ref 填写规范

- **留空**：使用 Nikki 仓库最新 Release Tag（例如 `v1.26.1`）
- **Tag 名**：例如 `v1.26.1`
- **分支名**：例如 `main`（跟踪该分支当前最新提交）
- **Commit SHA**：支持短 SHA 或完整 40 位 SHA，例如 `f06b6b44`

说明：界面上可填写短 SHA；工作流会自动解析为完整 40 位 SHA 后写入 feeds。feeds 中使用 `^` 分隔符（`url^完整SHA`），OpenWrt 编译系统以此实现 Git Commit 级别的精确钉定，而非 `;` Tag 分支跟踪。

#### 操作步骤

1. 打开仓库 [Actions 页面](https://github.com/Hawaiine/oasisic-openwrt/actions)
2. 在左侧工作流列表中选择 **openwrt-auto-build**
3. 点击 **Run workflow** 下拉按钮
4. 在 **force_build** 勾选框中决定是否强制构建（需要无视“版本未变化”判断时启用）
5. 在 **nikki_ref** 文本框中按上述规范填写（或留空使用默认 Tag）
6. 点击绿色的 **Run workflow** 确认运行
7. 等待流水线依次执行：check-upstream → build → qemu-smoke-test → release → persist-last-build
8. 构建完成后，在仓库 [Releases 页面](https://github.com/Hawaiine/oasisic-openwrt/releases) 查看产物
9. Release 标签格式：`oasisic-{OpenWrt版本}-nikki-{短SHA}`（例如 `oasisic-25.12.5-nikki-f06b6b4`）
10. 首次成功构建后，仓库中会自动新增/更新 `last_build_version` 文件。若 persist-last-build 步骤失败，版本去重机制可能失效（请检查分支保护规则是否允许 `GITHUB_TOKEN` 推送）

#### 推荐示例

**示例 A：立即构建包含 Nikki 某修复提交的固件**

- `force_build`：`true`
- `nikki_ref`：`f06b6b44`

说明：该提交对应「大文件保存乱码」等修复。工作流会自动解析为完整 SHA 后写入 feeds，使用 `^` 语法实现 Git Commit 级别钉定，确保可复现性。

**示例 B：跟踪 Nikki 主分支最新代码**

- `force_build`：`true`
- `nikki_ref`：`main`

说明：结果随 `main` 分支移动，可复现性弱于钉死 SHA。

**示例 C：与定时任务相同策略（仅手动重跑）**

- `force_build`：按需（不想等下次定时时启用）
- `nikki_ref`：留空

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
| 🔐 Nikki | `github.com/nikkinikki-org/OpenWrt-nikki` — 默认最新正式版 Tag，手动可指定分支或 Commit |
| 🧬 包声明 | `gen-config.sh` 显式声明所有包，无隐藏依赖 |
| 🧹 首次启动 | `uci-defaults/99-custom` 执行后自毁，含语言注册 + DNSPod 诊断地址 |
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
| LuCI 语言下拉框为空 | `luci.languages` 未注册（openwrt#16987） | 99-custom 中手动创建 `uci set luci.languages='internal'` + `uci set luci.languages.zh_cn='...'` |
| Feeds 更新失败 | 分支名语法错误 | 25.12 用 `;` 而非 `^` |
| `persist-last-build` 失败（403） | 分支保护禁止 `GITHUB_TOKEN` 推送 | 检查分支保护规则，允许 `GITHUB_TOKEN` 写入 |

### 编译时间参考

| 场景 | 首次 (cold) | 二次+ (ccache+缓存命中) |
|------|:-----------:|:----------------------:|
| 全量 SDK | ~77min | ~30-45min |

---

## 📌 相关项目

| 项目 | 说明 |
|------|------|
| 🏝️ [Oasisic-Icons](https://github.com/Hawaiine/Oasisic-Icons) | 代理图标库 |
| 🛡️ [mihomo-rules](https://github.com/Hawaiine/mihomo-rules) | mihomo 规则集 |
| 📺 [iptv-sources](https://github.com/Hawaiine/iptv-sources) | IPTV 直播源聚合 |
| 🎬 [moviepilot-category](https://github.com/Hawaiine/moviepilot-category) | MoviePilot 二级分类策略 |

---

## 📜 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| [oasisic-25.12.5](https://github.com/Hawaiine/oasisic-openwrt/releases/tag/oasisic-25.12.5) | 2026-07-22 | 🏝️ 自动构建 #95 — OpenWrt 25.12.5 + Nikki 1.26.1 + Kernel 6.12.94（含语言修复 + DNSPod 诊断） |
| `ef9c13d` | 2026-07-22 | 🐛 修复 LuCI 语言注册（`zh_cn` + `luci.languages` 手动创建）+ 诊断地址改 DNSPod + 清理无效 `luci.title.title` |
| [v1.0.0](https://github.com/Hawaiine/oasisic-openwrt/releases/tag/v1.0.0) | 2026-07-18 | 🏝️ **里程碑发布** — 四阶段全部完成，项目进入稳定生产阶段 |

**里程碑 v1.0.0 涵盖：**

| 阶段 | 内容 |
|------|------|
| 🔷 一 | 基础系统配置（网络/防火墙/DHCP/NTP/Feeds/包选择/编译优化） |
| 🔷 二 | 首次启动设置向导（状态机/检测页/CGI 前后端/自禁用/回滚保护/密码强度校验） |
| 🔷 三 | CI/CD 流水线（4 站式多阶段：check-upstream → build → qemu-smoke-test → release / 上游检测 / QEMU 烟雾测试 / minisign / Discord 通知 / 文档一致性校验 / 中英双语 ccache） |
| 🔷 四 | 密码安全（CI 随机密码 SHA-512 + 注释清理 + 写入校验 / 设置向导 CGI 密码修改）/ 内核版本正确提取 / 通用多阶段流水线拆分 |

> 后续版本跟随上游 OpenWrt / Nikki 自动发布，详见 [Releases](https://github.com/Hawaiine/oasisic-openwrt/releases)。

---

## 📜 许可证

[GNU General Public License v2](LICENSE) — 与 OpenWrt 项目保持一致。

---

> 🏝️ **Oasisic OpenWrt** — 自动构建 · 开箱即用 · 专为虚拟化优化