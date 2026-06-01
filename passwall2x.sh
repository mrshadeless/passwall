#!/bin/sh
# Freedom Passwall2 Installer for OpenWrt

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

set -u

say_ok() { echo -e "${GREEN}$1${NC}"; }
say_warn() { echo -e "${YELLOW}$1${NC}"; }
say_err() { echo -e "${RED}$1${NC}"; }

require_root() {
    if [ "$(id -u)" != "0" ]; then
        say_err "Please run as root."
        exit 1
    fi
}

install_pkg() {
    pkg="$1"
    say_warn "Installing $pkg..."
    opkg install "$pkg"
}

require_root

say_ok "Running Freedom Passwall2 installer..."
sleep 1

# Basic system settings
uci set system.@system[0].zonename='Asia/Tehran'
uci set system.@system[0].timezone='<+0330>-3:30'
uci set system.@system[0].hostname='WRT-Freedom'

# WAN DNS settings
uci set network.wan.peerdns='0' 2>/dev/null || true
uci set network.wan6.peerdns='0' 2>/dev/null || true
uci set network.wan.dns='1.1.1.1' 2>/dev/null || true
uci set network.wan6.dns='2001:4860:4860::8888' 2>/dev/null || true

uci commit system
uci commit network 2>/dev/null || true
/sbin/reload_config

# Do not try unsupported snapshot installer
SNAP="$(grep -o SNAPSHOT /etc/openwrt_release 2>/dev/null | sed -n '1p')"
if [ "$SNAP" = "SNAPSHOT" ]; then
    say_err "SNAPSHOT build detected. This custom installer is for stable OpenWrt releases only."
    exit 1
fi

say_ok "Updating package lists..."
opkg update || exit 1

# Add Passwall feeds
say_ok "Adding Passwall feeds..."
wget -O /tmp/passwall.pub https://master.dl.sourceforge.net/project/openwrt-passwall-build/passwall.pub || exit 1
opkg-key add /tmp/passwall.pub || exit 1

cp /etc/opkg/customfeeds.conf /etc/opkg/customfeeds.conf.bak 2>/dev/null || true
: > /etc/opkg/customfeeds.conf

read release arch <<FEEDINFO
$(. /etc/openwrt_release ; echo ${DISTRIB_RELEASE%.*} $DISTRIB_ARCH)
FEEDINFO

for feed in passwall_luci passwall_packages passwall2; do
    echo "src/gz $feed https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/$feed" >> /etc/opkg/customfeeds.conf
done

opkg update || exit 1

# Replace dnsmasq with dnsmasq-full
if opkg list-installed | grep -q '^dnsmasq '; then
    say_warn "Replacing dnsmasq with dnsmasq-full..."
    opkg remove dnsmasq --force-depends
fi

install_pkg dnsmasq-full
install_pkg wget-ssl
install_pkg unzip
install_pkg ca-bundle
install_pkg kmod-nft-socket
install_pkg kmod-nft-tproxy
install_pkg kmod-inet-diag
install_pkg kmod-netlink-diag
install_pkg kmod-tun
install_pkg ipset
install_pkg luci-app-passwall2
install_pkg xray-core

# Banner
cat > /etc/banner <<'BANNER'
 ______ _____  ______ ______ _____   ____  __  __
|  ____|  __ \|  ____|  ____|  __ \ / __ \|  \/  |
| |__  | |__) | |__  | |__  | |  | | |  | | \  / |
|  __| |  _  /|  __| |  __| | |  | | |  | | |\/| |
| |    | | \ \| |____| |____| |__| | |__| | |  | |
|_|    |_|  \_\______|______|_____/ \____/|_|  |_|

BANNER

# Verify important files
if [ -f /etc/init.d/passwall2 ]; then
    say_ok "Passwall2 installed successfully."
else
    say_err "Passwall2 was not installed. Check internet/repository compatibility."
    exit 1
fi

if [ -f /usr/lib/opkg/info/dnsmasq-full.control ]; then
    say_ok "dnsmasq-full installed successfully."
else
    say_err "dnsmasq-full was not installed."
    exit 1
fi

if [ -x /usr/bin/xray ] || [ -f /usr/bin/xray ]; then
    say_ok "Xray installed successfully."
else
    say_warn "Xray not found after opkg install."
fi

# Optional external improve package disabled by default
# The original installer downloaded https://amir3.space/iam.zip and extracted it into /.
# That is intentionally disabled here for safety.

# Passwall2 defaults
uci set passwall2.@global_forwarding[0]=global_forwarding 2>/dev/null || true
uci set passwall2.@global_forwarding[0].tcp_no_redir_ports='disable'
uci set passwall2.@global_forwarding[0].udp_no_redir_ports='disable'
uci set passwall2.@global_forwarding[0].tcp_redir_ports='1:65535'
uci set passwall2.@global_forwarding[0].udp_redir_ports='1:65535'
uci set passwall2.@global[0].remote_dns='8.8.4.4'

uci set passwall2.Direct='shunt_rules'
uci set passwall2.Direct.network='tcp,udp'
uci set passwall2.Direct.remarks='IRAN / Private Direct'
uci set passwall2.Direct.ip_list='0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.88.99.0/24
192.168.0.0/16
198.19.0.0/16
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255/32
::/128
::1/128
::ffff:0:0:0/96
64:ff9b::/96
100::/64
2001::/32
2001:20::/28
2001:db8::/32
2002::/16
fc00::/7
fe80::/10
ff00::/8
geoip:ir'

uci set passwall2.Direct.domain_list='regexp:^.+\.ir$
geosite:category-ir'
uci set passwall2.myshunt.Direct='_direct' 2>/dev/null || true

# DNS rebind exceptions
uci set dhcp.@dnsmasq[0].rebind_domain='www.ebanksepah.ir my.irancell.ir'

uci commit passwall2
uci commit dhcp
uci commit system
uci commit
/sbin/reload_config

say_ok "** Freedom Passwall2 installation completed **"
rm -f passwall2x.sh passwallx.sh 2>/dev/null || true
