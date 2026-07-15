#!/bin/bash
# ============================================================
# 根据 OpenWrt 版本 tag 生成 feeds.conf（精确版本跟踪）
# 用法: bash scripts/gen-feeds-conf.sh <owrt-version-tag> <nikki-tag>
# 示例: bash scripts/gen-feeds-conf.sh v25.12.5 v1.26.1
# ============================================================
set -e

OWRT_TAG="${1:?Usage: $0 <owrt-version-tag> <nikki-tag>}"
NIKKI_TAG="${2:?Usage: $0 <owrt-version-tag> <nikki-tag>}"

# 从版本 tag（如 v25.12.5）推导出分支名（如 openwrt-25.12）
OWRT_BRANCH="openwrt-$(echo "${OWRT_TAG#v}" | cut -d. -f1-2)"

cat << FEEDSEOF
src-git packages https://github.com/openwrt/packages.git;${OWRT_BRANCH}
src-git luci https://github.com/openwrt/luci.git;${OWRT_BRANCH}
src-git routing https://github.com/openwrt/routing.git;${OWRT_BRANCH}
src-git telephony https://github.com/openwrt/telephony.git;${OWRT_BRANCH}
src-git video https://github.com/openwrt/video.git;${OWRT_BRANCH}
src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;${NIKKI_TAG}
FEEDSEOF