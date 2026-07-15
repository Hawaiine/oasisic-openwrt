#!/usr/bin/env python3
"""Oasisic-OpenWrt → Discord 🖥️・固件发布 通知"""
import os, json, sys, subprocess
from datetime import datetime, timedelta, timezone

# Asia/Shanghai UTC+8
BJ_TZ = timezone(timedelta(hours=8))

channel_id = os.environ.get("DISCORD_CHANNEL_ID", "1524181167270531303")
token = os.environ.get("DISCORD_TOKEN", "")
if not token:
    print("❌ DISCORD_TOKEN 未设置", file=sys.stderr)
    sys.exit(1)

# 条件构建字段
fields = [
    {
        "name": "🏗️ **OpenWrt**",
        "value": f"`{os.environ.get('OWRT_VER', '?')}`",
        "inline": True
    },
    {
        "name": "📡 **Nikki**",
        "value": f"`{os.environ.get('NIKKI_VER', '?')}`",
        "inline": True
    },
]

# Kernel：仅当非空且非 ? 时显示
kernel_ver = os.environ.get('KERNEL_VER', '')
if kernel_ver and kernel_ver != '?':
    fields.append({
        "name": "🐧 **Kernel**",
        "value": f"`{kernel_ver}`",
        "inline": True
    })

fields.extend([
    {
        "name": "🏷️ **版本标签**",
        "value": f"`{os.environ.get('TAG', '?')}`",
        "inline": True
    },
    {
        "name": "📦 **下载链接**",
        "value": f"[🔗 前往 Release 页面]({os.environ.get('RELEASE_URL', '#')})",
        "inline": False
    },
    {
        "name": "⏱ **编译完成**",
        "value": f"{datetime.now(BJ_TZ).strftime('%Y-%m-%d %H:%M:%S')} 北京时间",
        "inline": False
    }
])

payload = {
    "embeds": [{
        "title": "🏝️ **Oasisic OpenWrt 固件已发布**",
        "color": 5814783,
        "thumbnail": {
            "url": "https://raw.githubusercontent.com/openwrt/branding/master/logo/openwrt_logo_square_blue_and_dark_blue.png"
        },
        "fields": fields,
        "footer": {
            "text": "Oasisic-OpenWrt · 自动构建",
            "icon_url": "https://avatars.githubusercontent.com/u/152380613?v=4"
        },
        "timestamp": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    }]
}

# 用 subprocess 调 curl，更可靠
cmd = [
    "curl", "-s", "-X", "POST",
    f"https://discord.com/api/v10/channels/{channel_id}/messages",
    "-H", f"Authorization: Bot {token}",
    "-H", "Content-Type: application/json",
    "-d", json.dumps(payload)
]
proc = subprocess.run(cmd, capture_output=True, text=True, timeout=15)

if proc.returncode == 0:
    result = json.loads(proc.stdout)
    if result.get("id"):
        print(f"✅ Discord 通知发送成功")
    else:
        print(f"❌ Discord 拒绝: {result.get('message', proc.stdout[:200])}")
        sys.exit(1)
else:
    print(f"❌ curl 失败: {proc.stderr}")
    sys.exit(1)