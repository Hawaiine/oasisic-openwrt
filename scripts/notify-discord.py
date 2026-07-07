#!/usr/bin/env python3
"""Oasisic-OpenWrt 固件发布 → Discord 🖥️・固件发布 通知脚本"""
import os, json, sys
from urllib.request import Request, urlopen

channel_id = os.environ.get("DISCORD_CHANNEL_ID", "1524181167270531303")
token = os.environ.get("DISCORD_TOKEN", "")
if not token:
    print("❌ DISCORD_TOKEN 未设置", file=sys.stderr)
    sys.exit(1)

owrt_ver    = os.environ.get("OWRT_VER", "?")
nikki_ver   = os.environ.get("NIKKI_VER", "?")
kernel_ver  = os.environ.get("KERNEL_VER", "?")
tag         = os.environ.get("TAG", "?")
release_url = os.environ.get("RELEASE_URL", "#")
build_time  = os.environ.get("BUILD_TIME", "?")

payload = {
    "embeds": [{
        "title": "🏝️ **Oasisic OpenWrt 固件已发布**",
        "color": 5814783,
        "thumbnail": {
            "url": "https://raw.githubusercontent.com/Hawaiine/Oasisic-Icons/main/icons/Devices/Router-1.png"
        },
        "fields": [
            {
                "name": "🏗️ **OpenWrt**",
                "value": f"`{owrt_ver}`",
                "inline": True
            },
            {
                "name": "📡 **Nikki**",
                "value": f"`{nikki_ver}`",
                "inline": True
            },
            {
                "name": "🐧 **Kernel**",
                "value": f"`{kernel_ver}`",
                "inline": True
            },
            {
                "name": "🏷️ **版本标签**",
                "value": f"`{tag}`",
                "inline": True
            },
            {
                "name": "📦 **下载链接**",
                "value": f"[🔗 前往 Release 页面]({release_url})",
                "inline": False
            },
            {
                "name": "⏱ **编译完成**",
                "value": f"{build_time} 北京时间",
                "inline": False
            }
        ],
        "footer": {
            "text": "Oasisic-OpenWrt · 自动构建",
            "icon_url": "https://avatars.githubusercontent.com/u/152380613?v=4"
        },
        "timestamp": __import__("datetime").datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    }]
}

req = Request(
    f"https://discord.com/api/v10/channels/{channel_id}/messages",
    data=json.dumps(payload).encode("utf-8"),
    headers={
        "Authorization": f"Bot {token}",
        "Content-Type": "application/json"
    }
)
resp = urlopen(req)
print(f"✅ Discord 通知发送成功 (HTTP {resp.status})")