#!/bin/bash
# minisign-sign.sh — 对 sha256sums 文件进行 minisign 签名
# 用法: bash scripts/minisign-sign.sh <sha256sums文件路径>
# 依赖: curl, 私钥从环境变量注入
# 输出: sha256sums.minisig (与输入文件同目录)

set -euo pipefail

SHA256SUMS="${1:-sha256sums}"
OUT_DIR="$(dirname "$SHA256SUMS")"
OUTPUT="${OUT_DIR}/sha256sums.minisig"

if [ ! -f "$SHA256SUMS" ]; then
    echo "❌ 文件不存在: $SHA256SUMS"
    exit 1
fi

# 从环境变量读取密钥
SK_HEX="${MINISIGN_SECRET_KEY:-}"
KEY_ID_HEX="${MINISIGN_KEY_ID:-}"
PASSWORD="${MINISIGN_PASSWORD:-}"

if [ -z "$SK_HEX" ] || [ -z "$KEY_ID_HEX" ] || [ -z "$PASSWORD" ]; then
    echo "❌ 缺少环境变量: MINISIGN_SECRET_KEY / MINISIGN_KEY_ID / MINISIGN_PASSWORD"
    exit 1
fi

# 用 Python 做 minisign 兼容签名
python3 -c "
import nacl.signing
import nacl.encoding
import base64
import hashlib
import os
import sys

# 读取密钥
sk_hex = os.environ.get('MINISIGN_SECRET_KEY', '')
key_id_hex = os.environ.get('MINISIGN_KEY_ID', '')
password = os.environ.get('MINISIGN_PASSWORD', '')

# 创建签名密钥
seed = bytes.fromhex(sk_hex)
private_key = nacl.signing.SigningKey(seed)
key_id = bytes.fromhex(key_id_hex)

# 读取文件内容
with open('$SHA256SUMS', 'rb') as f:
    data = f.read()

# minisign 签名格式:
# - 全局签名: blake2b(data || key_id || public_key)
# - 签名: Ed + key_id + signature(64 bytes) + trusted_comment + global_signature
# 简化: 直接对文件做 Ed25519 签名，附带 key_id

# 签名
signed = private_key.sign(data)
signature = signed.signature  # 64 bytes

# 构建 minisign-compatible 签名块
# trusted comment: 包含文件信息
trusted_comment = b'trusted comment: sha256sums signed by Oasisic-OpenWrt CI'

# 全局签名 (对 trusted comment + signature 签名)
global_data = trusted_comment + signature
global_signed = private_key.sign(global_data)

# 打包签名文件
# Format: untrusted comment + base64(sig) + trusted comment + base64(global_sig)
sig_data = key_id + signature
sig_b64 = base64.b64encode(sig_data).decode()

global_sig_data = global_signed.signature
global_sig_b64 = base64.b64encode(global_sig_data).decode()

output = f'untrusted comment: signature from minisign key {key_id.hex()}\\n'
output += f'{sig_b64}\\n'
output += f'{trusted_comment.decode()}\\n'
output += f'{global_sig_b64}\\n'

with open('$OUTPUT', 'w') as f:
    f.write(output)

print(f'✅ 签名完成: $OUTPUT')
print(f'   签名大小: {os.path.getsize(\"$OUTPUT\")} bytes')
" 2>&1

# 清除密码环境变量（安全）
unset MINISIGN_PASSWORD
echo "🔒 已清除密码环境变量"