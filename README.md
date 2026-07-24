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

**Oasisic OpenWrt** 是一套面向 x86_64 / PVE 的 OpenWrt 固件自动编译系统：从官方 SDK 全量编译，经 feeds 源码集成 Nikki（mihomo），构建后经 QEMU 烟雾测试，再发布 GitHub Release 并做 minisign 签名。

| | |
|---|---|
| 🏝️ **项目** | Oasisic OpenWrt |
| 📡 **流水线** | check-upstream → build → qemu-smoke-test → release → persist-last-build |
| 🎯 **上游跟踪** | OpenWrt 最新 Release Tag；Nikki 默认同最新 Release Tag，手动可覆盖为分支/Commit |
| ⏱ **耗时参考** | 冷构建约 60–100 分钟；缓存命中约 30–50 分钟（GitHub 免费 runner） |
| 📦 **产物** | squashfs 镜像 · ISO · sha256sums · minisig · feeds.conf.default · manifest |

---

## ✨ 特性一览

| 类别 | 说明 |
|------|------|
| 🏗️ 全量 SDK | 从 OpenWrt 源码编译，Nikki / mihomo-meta / luci-app-nikki 由 feeds 源码集成 |
| 🔄 定时 + 手动 | 每天北京时间 14:00 检测上游；Actions 可手动 `force_build` / `nikki_ref` |
| 📌 Nikki 钉定 | 解析 Tag/分支/短 SHA → 完整 40 位 SHA；feeds 使用 `url^SHA`（Commit）或 `url;Tag/分支` |
| 🏷️ Release 命名 | `oasisic-{OpenWrt版本}-nikki-{短SHA}`，避免同 OpenWrt 版互相覆盖 |
| 🧪 QEMU 门禁 | 启动固件，检查 LuCI HTTP 与 JS 资源 |
| 🔏 minisign | 对 `sha256sums` 签名，Release 附带 `sha256sums.minisig` |
| 🖥️ PVE | qemu-ga + virtio 驱动；默认 LAN DHCP，无硬编码局域网 IP |
| 🧭 首次向导 | 纯 HTML/CSS/JS + CGI；完成后自禁用 |
| 🈴 中文 LuCI | `99-custom` 注册 `luci.languages.zh_cn`（规避 openwrt#16987） |
| 🌐 诊断默认 | DNSPod `119.29.29.29` |
| 🧹 维护任务 | `cleanup-actions.yml` 每 3 天清理过期失败 run / 旧 cache |

---

## 🧭 设置向导（首次启动）

### 流程

```
开机 → 99-custom 创建 /etc/.oasisic-firstboot
     → 访问设备 IP → index.html 检测标记
     → 进入 setup.html 配置网络 / 密码（可跳过）
     → CGI 写 uci、清标记、重启服务
     → 之后进入 LuCI
```

### 关键文件

| 路径 | 说明 |
|------|------|
| `files/www/index.html` | 入口检测 |
| `files/www/setup.html` | 设置向导页 |
| `files/www/cgi-bin/setup` | 配置写入 |
| `files/www/cgi-bin/check-firstboot` | 首次启动状态查询 |
| `files/www/cgi-bin/setup-rollback` | 有时限回滚入口 |
| `files/etc/uci-defaults/99-custom` | 语言 / 诊断 / 网络默认 |
| `files/usr/lib/oasisic/firstboot.sh` | 首次启动状态机 |
| `files/usr/lib/oasisic/setup-rollback.sh` | 回滚逻辑（约 30 分钟有效） |

### 安全要点

- 无外部 CDN 依赖
- 仅首次启动标记存在时可写配置
- 完成后 CGI 自禁用（`chmod 000`）
- IPv4 / 端口 / 密码长度校验
- 支持跳过：只清标记、不改网络

### LuCI 中文注册

全新固件上 `luci.languages` 可能不存在，`99-custom` 会执行：

```sh
uci set luci.languages='internal'
uci set luci.languages.zh_cn='简体中文 (Simplified Chinese)'
uci set luci.main.lang='zh_cn'
```

使用 `zh_cn`（下划线）与 LuCI 翻译宏一致；相关上游问题见 [openwrt#16987](https://bugs.openwrt.org/index.php?do=details&task_id=16987)。

诊断地址默认：

```sh
uci set luci.diag.dns='119.29.29.29'
uci set luci.diag.ping='119.29.29.29'
uci set luci.diag.route='119.29.29.29'
```

---

## 🏗️ 编译流水线

### 五阶段

```
check-upstream
  │  解析 OpenWrt latest tag、Nikki ref → 完整 SHA
  │  composite = {OWRT_TAG}_nikki-{NIKKI_SHA}
  │  force_build / 与 last_build_version 比较 → should_build
  │
  ├── ⏭️ 无变化 → 结束
  │
  └── ✅ 需要构建 → build
        ├── 缓存恢复（ccache / 源码树 / dl+feeds）
        ├── 克隆 OpenWrt 指定 tag
        ├── 随机 root 密码写入 files/etc/shadow
        ├── gen-feeds-conf.sh + feeds update/install
        ├── gen-config.sh → defconfig → download → compile
        ├── minisign / 固件自检 / 文档一致性检查
        ├── 上传 Artifact
        ▼
      qemu-smoke-test（阻断门）
        ▼
      release（GitHub Release + Discord）
        ▼
      persist-last-build（回写 last_build_version，commit 含 [skip ci]）
```

### 缓存 Key（摘要）

| 缓存 | Key 要点 |
|------|----------|
| ccache | OpenWrt 版本 + `gen-config.sh` hash |
| 源码树 | OpenWrt 版本 + `gen-config.sh` hash |
| dl / feeds | OpenWrt 版本 + **Nikki 完整 SHA** + `gen-config.sh` hash |

清理缓存或删除 `last_build_version` 后，下一次为冷构建（更慢，结果更“干净”）。

### Feeds 语法（重要）

OpenWrt `scripts/feeds`：

| 写法 | 含义 |
|------|------|
| `url;Tag或分支` | `git clone --depth 1 --branch …` |
| `url^完整Commit` | clone 后 fetch/checkout 该 Commit |

本仓库 CI 在解析出 40 位 SHA 后生成：

```text
src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git^<40位SHA>
```

Tag/分支调试仍可用 `;v1.26.1` / `;main`。  
**不要**把完整 SHA 写成 `;SHA`（会报 `Remote branch … not found`）。

---

## 📂 项目结构

```
oasisic-openwrt/
├── .github/
│   ├── workflows/
│   │   ├── openwrt-auto-build.yml   # 主构建流水线
│   │   └── cleanup-actions.yml      # 定时清理失败 run / 旧 cache
│   └── minisign.pub
├── files/                           # 注入 rootfs 的文件
│   ├── etc/config/                  # network / firewall / system / dhcp
│   ├── etc/uci-defaults/99-custom
│   ├── etc/shadow                   # CI 运行时写入随机 root 哈希
│   ├── usr/lib/oasisic/
│   └── www/                         # 向导 + CGI
├── scripts/
│   ├── gen-config.sh
│   ├── gen-feeds-conf.sh
│   ├── check-firmware.sh
│   ├── check-docs-consistency.sh
│   ├── minisign-sign.sh
│   └── notify-discord.py
├── feeds.conf                       # 本地参考；CI 以 gen-feeds-conf 输出为准
├── LICENSE                          # GPLv2
└── README.md
```

`last_build_version`：**不在仓库常驻树中保证存在**。构建成功后由 `persist-last-build` 写入/更新；删除该文件可强制下次按“无历史版本”重新构建。

默认分支为 **`main`**。请勿长期保留与 main 分叉的临时修复分支。

---

## 🚀 使用说明

### 1. Secrets

| Secret | 用途 |
|--------|------|
| `DISCORD_BOT_TOKEN` | 发布通知（可选，缺则通知步骤失败但不影响你本地使用固件逻辑） |
| `MINISIGN_SECRET_KEY` | 签名私钥（hex） |
| `MINISIGN_KEY_ID` | 密钥 ID（hex） |
| `MINISIGN_PASSWORD` | 私钥密码 |

### 2. 定时构建

- 工作流：`openwrt-auto-build`
- 时间：UTC 06:00 / **北京时间 14:00**
- Nikki 默认：最新正式版 Release Tag
- 仅有 Nikki 新 Commit、尚未发 Tag 时，**定时不会自动带上该 Commit**

### 3. 手动构建（workflow_dispatch）

[Actions → openwrt-auto-build → Run workflow](https://github.com/Hawaiine/oasisic-openwrt/actions/workflows/openwrt-auto-build.yml)

| 参数 | 类型 | 默认 | 含义 |
|------|------|------|------|
| `force_build` | 布尔勾选 | false | 跳过版本比对，强制全量编译 |
| `nikki_ref` | 字符串 | 空 | 空=最新 Nikki Tag；可填 Tag / 分支 / 短或完整 SHA |

**`nikki_ref` 规范**

- 留空 → 最新 Release Tag（如 `v1.26.1`）
- Tag → `v1.26.1`
- 分支 → `main`
- Commit → `f06b6b44` 或 40 位完整 SHA（界面可短，CI 解析为完整 SHA 再写 feeds）

**示例**

| 目的 | force_build | nikki_ref |
|------|-------------|-----------|
| 钉死某 Commit 验证 | true | `f06b6b44` |
| 跟踪 Nikki main | true | `main` |
| 与定时相同策略手动重跑 | 按需 | 留空 |

成功后：

1. [Releases](https://github.com/Hawaiine/oasisic-openwrt/releases) 下载产物  
2. 标签形如 `oasisic-25.12.5-nikki-f06b6b4`  
3. 正文含 root 随机密码、Nikki ref、内核版本  
4. 可选出现/更新 `last_build_version`（`persist-last-build` 依赖 token 可推 main）

### 4. PVE 导入

```bash
# 下载 Release 中的 EFI 镜像并解压
gunzip openwrt-x86-64-generic-squashfs-combined-efi.img.gz

qm create 100 --name "Oasisic-OpenWrt" --ostype l26 \
  --machine q35 --bios ovmf --cores 2 --memory 1024 \
  --net0 virtio,bridge=vmbr0

qm importdisk 100 openwrt-x86-64-generic-squashfs-combined-efi.img local-lvm
qm set 100 --scsihw virtio-scsi-single --scsi0 local-lvm:vm-100-disk-0
qm set 100 --boot order=scsi0 --agent enabled=1
qm start 100
```

首次启动为 **DHCP 客户端**。到主路由 DHCP 列表查找主机名 `Oasisic-OpenWrt`，浏览器打开 IP 进入设置向导。root 密码以对应 Release 正文为准。

---

## 🛡️ 安全与源

| 项 | 说明 |
|----|------|
| OpenWrt | 仅官方 `openwrt/openwrt` 对应 Release Tag |
| feeds | 官方 packages/luci/routing/telephony/video + Nikki |
| 包列表 | `scripts/gen-config.sh` 显式声明 |
| 密码 | 每次 CI 构建生成随机 root 哈希；向导可再改 |
| 签名 | minisign；公钥见 `.github/minisign.pub` |

---

## 🔧 排错

| 症状 | 可能原因 | 处理 |
|------|----------|------|
| `Remote branch <sha> not found` | feeds 把 Commit 写成了 `;SHA` | 必须用 `^完整SHA`（见 `gen-feeds-conf.sh`） |
| feeds / download 网络失败 | 上游瞬时故障 | workflow 已重试；再手动 Run |
| checkout action `429` | GitHub 限流 | 多为 warning，重试后常可继续 |
| LuCI 语言列表空 | languages 未注册 | 确认固件含当前 `99-custom` |
| LuCI 转圈 / JS 异常 | 缺 ucode 或静态资源 | 配置中已含 ucode；看 QEMU 步骤日志 |
| `persist-last-build` 失败 | 无法推 main | 检查 token/分支保护；去重会失效 |
| 想强制全新构建 | 缓存或版本文件残留 | 清 Actions Cache；删除 `last_build_version`；`force_build=true` |

### 时间参考（免费 runner，含 Nikki）

| 场景 | 约耗时 |
|------|--------|
| 冷构建（无 cache） | 60–100 分钟 |
| 缓存命中 | 30–50 分钟 |

---

## 📌 相关项目

| 项目 | 说明 |
|------|------|
| [Oasisic-Icons](https://github.com/Hawaiine/Oasisic-Icons) | 代理图标 |
| [mihomo-rules](https://github.com/Hawaiine/mihomo-rules) | mihomo 规则集 |
| [iptv-sources](https://github.com/Hawaiine/iptv-sources) | IPTV 源聚合 |
| [moviepilot-category](https://github.com/Hawaiine/moviepilot-category) | MoviePilot 分类策略 |

---

## 📜 版本与发布

- **以 [Releases](https://github.com/Hawaiine/oasisic-openwrt/releases) 为准**，不再维护易过期的手工版本表。  
- 标签格式：`oasisic-{OpenWrt版本号}-nikki-{短SHA}`。  
- 工程变更看 `git log` / Actions；不在此逐条罗列构建编号。

当前仓库若暂无 Release，说明产物已清理或尚未发布新构建——请直接跑手动/定时流水线生成。

---

## 📜 许可证

[GNU General Public License v2](LICENSE) — 与 OpenWrt 一致。

---

> 🏝️ **Oasisic OpenWrt** — 自动构建 · 开箱即用 · 面向虚拟化
