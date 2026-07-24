#!/bin/bash
# ============================================================
# 根据 OpenWrt 版本 tag 和 Nikki ref 生成 feeds.conf
# 用法: bash scripts/gen-feeds-conf.sh <owrt-version-tag> <nikki-sha>
# 示例:
#   bash scripts/gen-feeds-conf.sh v25.12.5 f06b6b4489... # 完整 40 位 sha
#   bash scripts/gen-feeds-conf.sh v25.12.5 v1.26.1       # tag（仍可用）
# 注意: workflow 始终传入已解析的完整 40 位 sha 以保证 feeds 确定性
# ============================================================
set -e

OWRT_TAG="${1:?Usage: $0 <owrt-version-tag> <nikki-ref>}"
NIKKI_REF="${2:?Usage: $0 <owrt-version-tag> <nikki-ref>}"

# 从版本 tag（如 v25.12.5）推导出分支名（如 openwrt-25.12）
OWRT_BRANCH="openwrt-$(echo "${OWRT_TAG#v}" | cut -d. -f1-2)"

cat << FEEDSEOF
src-git packages https://github.com/openwrt/packages.git;${OWRT_BRANCH}
src-git luci https://github.com/openwrt/luci.git;${OWRT_BRANCH}
src-git routing https://github.com/openwrt/routing.git;${OWRT_BRANCH}
src-git telephony https://github.com/openwrt/telephony.git;${OWRT_BRANCH}
src-git video https://github.com/openwrt/video.git;${OWRT_BRANCH}
src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;${NIKKI_REF}
FEEDSEOF
