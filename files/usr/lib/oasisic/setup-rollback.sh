#!/bin/sh
# ============================================================
# Oasisic OpenWrt — 设置向导回滚脚本
# 从 /tmp/.setup-original 恢复原始网络配置
# 用法: /usr/lib/oasisic/setup-rollback.sh
# ============================================================

ORIG_NET="/tmp/.setup-original"
ORIG_UHTTPD="/tmp/.setup-original-uhttpd"

if [ ! -f "$ORIG_NET" ]; then
    echo '{"success":false,"error":"没有可回滚的配置"}'
    exit 0
fi

# 从保存的配置中提取原始 proto
OLD_PROTO=$(grep 'network.lan.proto=' "$ORIG_NET" 2>/dev/null | head -1 | cut -d"'" -f2)
OLD_IP=$(grep 'network.lan.ipaddr=' "$ORIG_NET" 2>/dev/null | head -1 | cut -d"'" -f2)
OLD_MASK=$(grep 'network.lan.netmask=' "$ORIG_NET" 2>/dev/null | head -1 | cut -d"'" -f2)
OLD_GW=$(grep 'network.lan.gateway=' "$ORIG_NET" 2>/dev/null | head -1 | cut -d"'" -f2)

# 恢复网络配置
uci set network.lan.proto="${OLD_PROTO:-dhcp}"
if [ -n "$OLD_IP" ]; then
    uci set network.lan.ipaddr="$OLD_IP"
fi
if [ -n "$OLD_MASK" ]; then
    uci set network.lan.netmask="$OLD_MASK"
fi
if [ -n "$OLD_GW" ]; then
    uci set network.lan.gateway="$OLD_GW"
fi

# 恢复 uhttpd 端口（如果备份存在）
if [ -f "$ORIG_UHTTPD" ]; then
    OLD_PORT=$(grep 'uhttpd.main.listen_http=' "$ORIG_UHTTPD" 2>/dev/null | head -1 | cut -d"'" -f2)
    if [ -n "$OLD_PORT" ]; then
        uci del uhttpd.main.listen_http 2>/dev/null || true
        uci add_list uhttpd.main.listen_http="$OLD_PORT"
    fi
fi

uci commit network
uci commit uhttpd

# 清理标记文件
rm -f "$ORIG_NET" "$ORIG_UHTTPD"

# 重启网络
/etc/init.d/network reload 2>/dev/null &
/etc/init.d/uhttpd restart 2>/dev/null &

echo '{"success":true,"mode":"rollback"}'