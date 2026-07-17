#!/bin/bash
# ============================================================
# 生成 OpenWrt 全量 SDK 编译用的 .config 文件
# 用法: bash scripts/gen-config.sh <build-dir>
# ============================================================
set -e

BUILD_DIR="${1:-openwrt}"
CONFIG_FILE="${BUILD_DIR}/.config"

cat > "$CONFIG_FILE" << 'CONFIGEOF'
# ─── 目标平台 ──────────────────────────────────────────
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y

# ─── 镜像格式 ──────────────────────────────────────────
CONFIG_TARGET_ROOTFS_PARTSIZE=512
CONFIG_TARGET_KERNEL_PARTSIZE=32
CONFIG_GRUB_TIMEOUT="3"
CONFIG_GRUB_TITLE="Oasisic OpenWrt"
CONFIG_ISO_IMAGES=y
CONFIG_VMDK_IMAGES=n
CONFIG_GRUB_IMAGES=y
CONFIG_TARGET_IMAGES_GZIP=y

# ─── 语言 ──────────────────────────────────────────────
CONFIG_LUCI_LANG_zh_Hans=y

# ─── 语言包 ────────────────────────────────────────────
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-nikki-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-filemanager-zh-cn=y
CONFIG_PACKAGE_luci-i18n-package-manager-zh-cn=y

# ─── DNS ──────────────────────────────────────────────
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dnsmasq_full_dhcp=y
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_dnsmasq_full_dnssec=y
CONFIG_PACKAGE_dnsmasq_full_nftset=y
CONFIG_PACKAGE_dnsmasq_full_auth=y
CONFIG_PACKAGE_dnsmasq_full_conntrack=y
CONFIG_PACKAGE_dnsmasq_full_tftp=y
CONFIG_PACKAGE_dnsmasq_full_noid=y

# ─── 防火墙 / 网络 ─────────────────────────────────────
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_nftables-json=y
CONFIG_PACKAGE_nftables=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_yq=y
CONFIG_PACKAGE_cgi-io=y

# ─── IPv6 ─────────────────────────────────────────────
CONFIG_PACKAGE_odhcp6c=y
CONFIG_PACKAGE_luci-proto-ipv6=y

# ─── Nikki 代理（从 feeds 编译） ─────────────────────────
CONFIG_PACKAGE_nikki=y
CONFIG_PACKAGE_mihomo-meta=y
CONFIG_PACKAGE_luci-app-nikki=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-inet-diag=y
CONFIG_PACKAGE_kmod-nf-conntrack-netlink=y
CONFIG_PACKAGE_kmod-nf-socket=y
CONFIG_PACKAGE_kmod-nf-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-dummy=y
CONFIG_PACKAGE_libbpf=y

# ─── PVE 集成 ───────────────────────────────────────────
CONFIG_PACKAGE_qemu-ga=y
CONFIG_PACKAGE_kmod-virtio-serial=y
CONFIG_PACKAGE_kmod-virtio-net=y
CONFIG_PACKAGE_kmod-virtio-blk=y
CONFIG_PACKAGE_kmod-virtio-scsi=y
CONFIG_PACKAGE_kmod-virtio-rng=y

# ─── LuCI 核心 ──────────────────────────────────────────
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-lib-uqr=y
CONFIG_PACKAGE_luci-lua-runtime=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-filemanager=y
CONFIG_PACKAGE_luci-app-package-manager=y

# ─── 主题 ──────────────────────────────────────────────
CONFIG_PACKAGE_luci-theme-bootstrap=y

# ─── RPCD ──────────────────────────────────────────────
CONFIG_PACKAGE_rpcd=y
CONFIG_PACKAGE_rpcd-mod-file=y
CONFIG_PACKAGE_rpcd-mod-iwinfo=y
CONFIG_PACKAGE_rpcd-mod-luci=y
CONFIG_PACKAGE_rpcd-mod-rrdns=y
CONFIG_PACKAGE_rpcd-mod-ucode=y
CONFIG_PACKAGE_ucode=y
CONFIG_PACKAGE_ucode-mod-html=y
CONFIG_PACKAGE_ucode-mod-log=y
CONFIG_PACKAGE_ucode-mod-json=y
CONFIG_PACKAGE_ucode-mod-lua=y
CONFIG_PACKAGE_ucode-mod-math=y

# ─── Web 服务器 ─────────────────────────────────────────
CONFIG_PACKAGE_uhttpd=y
CONFIG_PACKAGE_uhttpd-mod-ubus=y

# ─── 工具 ──────────────────────────────────────────────
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_vim=y
CONFIG_PACKAGE_libpcre2=y
CONFIG_PCRE2_JIT_ENABLED=y

# ─── SSL / 安全 ─────────────────────────────────────────
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_openssl-util=y
CONFIG_PACKAGE_libopenssl=y
CONFIG_LIBCURL_MBEDTLS=y
CONFIG_OPENSSL_ENGINE=y
CONFIG_OPENSSL_WITH_TLS13=y
CONFIG_OPENSSL_OPTIMIZE_SPEED=y
CONFIG_OPENSSL_WITH_ASM=y
CONFIG_LIBCURL_PROXY=y
CONFIG_LIBCURL_HTTP2=y

# ─── 时区 ──────────────────────────────────────────────
CONFIG_PACKAGE_zoneinfo-asia=y
CONFIG_PACKAGE_zoneinfo-core=y

# ─── 额外内核模块 ───────────────────────────────────────
CONFIG_PACKAGE_kmod-acpi-video=y
CONFIG_PACKAGE_kmod-amazon-ena=y
CONFIG_PACKAGE_kmod-amd-xgbe=y
CONFIG_PACKAGE_kmod-bnx2=y
CONFIG_PACKAGE_kmod-button-hotplug=y
CONFIG_PACKAGE_kmod-drm-i915=y
CONFIG_PACKAGE_kmod-dwmac-intel=y
CONFIG_PACKAGE_kmod-e1000=y
CONFIG_PACKAGE_kmod-e1000e=y
CONFIG_PACKAGE_kmod-forcedeth=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-igb=y
CONFIG_PACKAGE_kmod-igc=y
CONFIG_PACKAGE_kmod-ixgbe=y
CONFIG_PACKAGE_kmod-r8169=y
CONFIG_PACKAGE_kmod-tg3=y
CONFIG_PACKAGE_kmod-pps=y
CONFIG_PACKAGE_kmod-ptp=y
CONFIG_PACKAGE_kmod-stmmac-core=y
CONFIG_PACKAGE_kmod-phy-realtek=y

# ─── Network drivers (PVE virtio) ──────────────────────
CONFIG_PACKAGE_kmod-dma-buf=y
CONFIG_PACKAGE_kmod-drm=y
CONFIG_PACKAGE_kmod-drm-kms-helper=y
CONFIG_PACKAGE_kmod-drm-ttm=y
CONFIG_PACKAGE_kmod-fb=y

# ─── PPPoE ────────────────────────────────────────────
CONFIG_PACKAGE_ppp=y
CONFIG_PACKAGE_ppp-mod-pppoe=y
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-slhc=y
CONFIGEOF

echo "✅ .config 已生成: $CONFIG_FILE ($(wc -l < "$CONFIG_FILE") 行)"