#!/bin/sh

# ==========================================
# Freedom Passwall2 Installer for OpenWrt
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}"
echo "=========================================="
echo "      FREEDOM PASSWALL2 INSTALLER"
echo "=========================================="
echo -e "${NC}"

sleep 2

# -------------------------------
# System Configuration
# -------------------------------

echo -e "${GREEN}Configuring system...${NC}"

uci set system.@system[0].zonename='Asia/Tehran'
uci set system.@system[0].timezone='<+0330>-3:30'
uci set system.@system[0].hostname='WRT-Freedom'

# Use DNS provided by upstream/peer
 uci set network.wan.peerdns='1' 
 uci set network.wan6.peerdns='1'

# Use Custom DNS 
#uci set network.wan.peerdns='0'
#uci set network.wan6.peerdns='0'
#uci set network.wan.dns='1.1.1.1'
#uci set network.wan6.dns='2001:4860:4860::8888'

uci commit system
uci commit network

/sbin/reload_config

# -------------------------------
# Snapshot Detection
# -------------------------------

SNAP="$(grep -o SNAPSHOT /etc/openwrt_release | sed -n '1p')"

if [ "$SNAP" = "SNAPSHOT" ]; then
    echo -e "${RED}SNAPSHOT builds are not supported by this installer.${NC}"
    exit 1
fi

# -------------------------------
# Package Update
# -------------------------------

echo -e "${GREEN}Updating package lists...${NC}"

opkg update || {
    echo -e "${RED}opkg update failed.${NC}"
    exit 1
}

# -------------------------------
# Add Passwall Feed
# -------------------------------

echo -e "${GREEN}Adding Passwall feeds...${NC}"

wget -O /tmp/passwall.pub \
https://master.dl.sourceforge.net/project/openwrt-passwall-build/passwall.pub

opkg-key add /tmp/passwall.pub

cp /etc/opkg/customfeeds.conf \
/etc/opkg/customfeeds.conf.bak 2>/dev/null

: > /etc/opkg/customfeeds.conf

read release arch << EOF
$(. /etc/openwrt_release ; \
echo ${DISTRIB_RELEASE%.*} $DISTRIB_ARCH)
EOF

for feed in passwall_luci passwall_packages passwall2; do
    echo "src/gz $feed \
https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/$feed" \
>> /etc/opkg/customfeeds.conf
done

opkg update || {
    echo -e "${RED}Feed update failed.${NC}"
    exit 1
}

# -------------------------------
# Install Required Packages
# -------------------------------

echo -e "${GREEN}Installing packages...${NC}"

opkg remove dnsmasq --force-depends

PACKAGES="
dnsmasq-full
wget-ssl
curl
ca-bundle
unzip
luci-app-passwall2
xray-core
ipset
kmod-nft-socket
kmod-nft-tproxy
kmod-inet-diag
kmod-netlink-diag
kmod-tun
"

for pkg in $PACKAGES; do
    echo -e "${YELLOW}Installing: $pkg${NC}"
    opkg install "$pkg"
done

# -------------------------------
# Verify Installation
# -------------------------------

if [ ! -f /etc/init.d/passwall2 ]; then
    echo -e "${RED}Passwall2 installation failed.${NC}"
    exit 1
fi

if [ ! -f /usr/bin/xray ]; then
    echo -e "${RED}Xray installation failed.${NC}"
    exit 1
fi

# -------------------------------
# Freedom Banner
# -------------------------------

cat > /etc/banner << 'EOF'
 ______ _____  ______ ______ _____   ____  __  __
|  ____|  __ \|  ____|  ____|  __ \ / __ \|  \/  |
| |__  | |__) | |__  | |__  | |  | | |  | | \  / |
|  __| |  _  /|  __| |  __| | |  | | |  | | |\/| |
| |    | | \ \| |____| |____| |__| | |__| | |  | |
|_|    |_|  \_\______|______|_____/ \____/|_|  |_|

EOF

# -------------------------------
# Passwall2 Configuration
# -------------------------------

echo -e "${GREEN}Applying Passwall2 configuration...${NC}"

uci set passwall2.@global_forwarding[0]=global_forwarding

uci set passwall2.@global_forwarding[0].tcp_no_redir_ports='disable'
uci set passwall2.@global_forwarding[0].udp_no_redir_ports='disable'

uci set passwall2.@global_forwarding[0].tcp_redir_ports='1:65535'
uci set passwall2.@global_forwarding[0].udp_redir_ports='1:65535'

uci set passwall2.@global[0].remote_dns='8.8.8.8'

uci set passwall2.Direct='shunt_rules'
uci set passwall2.Direct.network='tcp,udp'
uci set passwall2.Direct.remarks='IRAN'
uci set passwall2.Direct.ip_list='geoip:ir'
uci set passwall2.Direct.domain_list='regexp:^.+\.ir$
geosite:category-ir'

uci set passwall2.myshunt.Direct='_direct'

# -------------------------------
# Custom Passwall2 Status Page
# -------------------------------

echo -e "${GREEN}Installing custom Passwall2 status page...${NC}"

STATUS_DIR="/usr/lib/lua/luci/view/passwall2/global"
STATUS_FILE="$STATUS_DIR/status.htm"
BACKUP_FILE="$STATUS_DIR/status.htm.bak"

if [ -f "$STATUS_FILE" ]; then
    cp "$STATUS_FILE" "$BACKUP_FILE"
fi

wget -O "$STATUS_FILE" \
https://raw.githubusercontent.com/mrshadeless/passwall/refs/heads/main/status.htm

if [ -f "$STATUS_FILE" ]; then
    echo -e "${GREEN}Custom status.htm installed successfully.${NC}"
else
    echo -e "${RED}Failed to install custom status.htm.${NC}"
    exit 1
fi

# -------------------------------
# Commit Config
# -------------------------------

uci commit passwall2
uci commit system
uci commit network
uci commit dhcp

# -------------------------------
# Reload Config
# -------------------------------

/sbin/reload_config

# -------------------------------
# Final Message
# -------------------------------

echo ""
echo -e "${GREEN}=========================================="
echo "  PASSWALL2 INSTALLATION COMPLETED"
echo "==========================================${NC}"

echo ""
echo -e "${CYAN}Hostname:${NC} WRT-Freedom"
echo -e "${CYAN}Access:${NC} Services -> Passwall2"
echo ""
