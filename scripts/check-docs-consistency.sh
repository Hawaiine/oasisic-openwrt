#!/bin/bash
# ============================================================
# Oasisic OpenWrt — 文档一致性自检
# 校验 README.md 中明确声称的功能包在 gen-config.sh 中确实启用
# 用法: bash scripts/check-docs-consistency.sh
# ============================================================
set -euo pipefail

PASS=0
FAIL=0
WARN=0

check() {
    local desc="$1"
    local status="$2"
    local mode="${3:-fail}"
    if [ "$status" -eq 0 ]; then
        echo "  ✅ $desc"
        PASS=$((PASS + 1))
    elif [ "$mode" = "warn" ]; then
        echo "  ⚠️  $desc"
        WARN=$((WARN + 1))
    else
        echo "  ❌ $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "═══════════════════════════════════════════"
echo "  文档一致性检查"
echo "═══════════════════════════════════════════"
echo ""

CONFIG_FILE="scripts/gen-config.sh"
README_FILE="README.md"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 未找到 $CONFIG_FILE"
    exit 1
fi

# ─── 1. 校验 README 声称的包确实在 gen-config.sh 中启用 ──
echo "◆ 校验 README 声称的功能包"
echo ""

# 格式: "README关键词|CONFIG_PACKAGE_名|说明"
CLAIMS=(
    "Nikki|nikki|代理 Nikki 核心包"
    "mihomo|mihomo-meta|mihomo 核心引擎"
    "luci-app-nikki|luci-app-nikki|Nikki LuCI 插件"
    "Guest Agent|qemu-ga|QEMU Guest Agent (PVE)"
    "virtio|kmod-virtio-net|virtio 网卡驱动"
    "virtio|kmod-virtio-blk|virtio 块设备驱动"
    "virtio|kmod-virtio-scsi|virtio SCSI 驱动"
    "virtio|kmod-virtio-rng|virtio 随机数驱动"
    "dnsmasq|dnsmasq-full|DNS/DHCP 核心"
    "ucode|ucode|LuCI ucode 解释器"
    "bootstrap|luci-theme-bootstrap|Bootstrap 主题"
    "minisign|minisign|固件签名工具（注：非 CONFIG_PACKAGE，跳过）"
)

for claim in "${CLAIMS[@]}"; do
    IFS='|' read -r keyword pkg desc <<< "$claim"
    # 跳过特殊标注
    if echo "$desc" | grep -q "跳过"; then
        continue
    fi
    if grep -qi "$keyword" "$README_FILE" 2>/dev/null; then
        if grep -q "CONFIG_PACKAGE_${pkg}=y" "$CONFIG_FILE" 2>/dev/null; then
            check "README 声称「$keyword」→ $pkg 已启用 ($desc)" 0 warn
        else
            check "README 声称「$keyword」但 $pkg 未在 gen-config.sh 中启用" 1
        fi
    fi
done

# ─── 2. 校验 gen-config.sh 中被注释的包是否与 README 一致 ──
echo ""
echo "◆ 校验 gen-config.sh 中被排除的包"
echo ""

EXCLUDED=(
    "iperf3"
    "lm-sensors"
    "luci-compat"
    "luci-theme-argon"
)

for pkg in "${EXCLUDED[@]}"; do
    # 检查是否在 gen-config.sh 中被注释或标记移除
    if grep -qE "# CONFIG_PACKAGE_${pkg}[= ]" "$CONFIG_FILE" 2>/dev/null; then
        # 检查 README 是否说明已移除
        if grep -qi "$pkg" "$README_FILE" 2>/dev/null; then
            check "README 已说明「$pkg」已移除" 0 warn
        else
            check "gen-config.sh 排除了 $pkg 但 README 未提及" 1
        fi
    fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "  结果: $PASS ✅  /  $FAIL ❌  /  $WARN ⚠️"
echo "═══════════════════════════════════════════"
echo "ℹ️  所有检查均为信息级，不阻断构建"
exit 0