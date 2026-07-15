#!/bin/sh
# firstboot.sh — Oasisic 统一首次启动状态机
# 用于所有需要首次启动校验的 CGI 脚本和设置向导
# 状态文件路径: /etc/.oasisic-firstboot
# 使用方法: source /usr/lib/oasisic/firstboot.sh
#
# 可用函数:
#   oasisic_is_firstboot()          — 返回 0 如果状态文件存在
#   oasisic_require_firstboot_or_exit() — 非首次直接返回错误 JSON 并 exit 0
#   oasisic_clear_firstboot()       — 清除状态文件 + 可选的自我禁用

OASISIC_FIRSTBOOT_FILE="/etc/.oasisic-firstboot"

# 检查状态文件是否存在
oasisic_is_firstboot() {
    [ -f "$OASISIC_FIRSTBOOT_FILE" ]
}

# 非首次配置态直接返回错误 JSON 并 exit 0
oasisic_require_firstboot_or_exit() {
    if ! oasisic_is_firstboot; then
        echo '{"success":false,"error":"设置向导已完成，此接口已禁用"}'
        exit 0
    fi
}

# 清除首次启动标记
# 用法: oasisic_clear_firstboot [调用者脚本路径]
# 如果传入调用者脚本路径，会执行 chmod 000 做二次防护
oasisic_clear_firstboot() {
    rm -f "$OASISIC_FIRSTBOOT_FILE"
    if [ -n "${1:-}" ] && [ -f "$1" ]; then
        chmod 000 "$1" 2>/dev/null || true
    fi
}