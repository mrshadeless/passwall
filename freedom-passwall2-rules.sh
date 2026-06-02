#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Applying Freedom Passwall2 rules...${NC}"

if [ ! -f /etc/config/passwall2 ]; then
    echo -e "${RED}/etc/config/passwall2 not found. Install Passwall2 first.${NC}"
    exit 1
fi

BACKUP="/etc/config/passwall2.backup.$(date +%Y%m%d-%H%M%S)"
cp /etc/config/passwall2 "$BACKUP"
echo -e "${YELLOW}Backup created: $BACKUP${NC}"

ensure_anon_section() {
    SECTION_TYPE="$1"
    uci -q get "passwall2.@${SECTION_TYPE}[0]" >/dev/null 2>&1 || uci add passwall2 "$SECTION_TYPE" >/dev/null
}

# -------------------------------
# Remove old rules
# -------------------------------

echo -e "${YELLOW}Removing existing Passwall2 shunt rules...${NC}"

for section in $(uci show passwall2 | grep '=shunt_rules' | cut -d. -f2 | cut -d= -f1); do
    uci -q delete passwall2."$section"
done

# -------------------------------
# DNS Rule
# -------------------------------

uci set passwall2.DNS='shunt_rules'
uci set passwall2.DNS.remarks='DNS'
uci set passwall2.DNS.network='tcp,udp'
uci set passwall2.DNS.ip_list='#Google DNS
8.8.4.4
8.8.8.8
#Open DNS
208.67.222.222
208.67.220.220
#Cloudflare DNS
1.1.1.1
1.1.1.2
1.0.0.1
#Quad9 DNS
9.9.9.9
149.112.112.112
#Quad9 IPv6
2001:67c:4e8::/48
2001:b28:f23c::/48
2001:b28:f23d::/48
2001:b28:f23f::/48
2001:b28:f242::/48
#Google IPv6 DNS
2001:4860:4860::8888
2001:4860:4860::8844
#Cloudflare IPv6 DNS
2606:4700:4700::1111
2606:4700:4700::1001'

# -------------------------------
# Private IPs Rule
# -------------------------------

uci set passwall2.PrivateIPs='shunt_rules'
uci set passwall2.PrivateIPs.remarks='PrivateIPs'
uci set passwall2.PrivateIPs.network='tcp,udp'
uci set passwall2.PrivateIPs.ip_list='0.0.0.0/8
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
ff00::/8'

# -------------------------------
# IRAN Rule
# -------------------------------

uci set passwall2.IRAN='shunt_rules'
uci set passwall2.IRAN.remarks='IRAN'
uci set passwall2.IRAN.protocol='bittorrent'
uci set passwall2.IRAN.network='tcp,udp'
uci set passwall2.IRAN.domain_list='30nama.com
onlinedigi.top
deserver.top
masoudsajadi.com
dgmovie.fun
regexp:^digimoviez.*\.top$
regexp:^.+\.ir$
geosite:ir'
uci set passwall2.IRAN.ip_list='
#BPI / Arvan
185.143.235.201
185.143.232.201
188.114.97.2
188.114.96.2
104.28.243.190
#Digimovie
185.137.24.14
geoip:ir'

# -------------------------------
# Direct Game Rule
# -------------------------------

uci set passwall2.DirectGame='shunt_rules'
uci set passwall2.DirectGame.remarks='DirectGame'
uci set passwall2.DirectGame.network='tcp,udp'
uci set passwall2.DirectGame.domain_list='api.steampowered.com
regexp:\.cm.steampowered.com$
regexp:\.steamserver.net$
geosite:category-games@cn'
uci set passwall2.DirectGame.ip_list='103.10.124.0/24
103.10.125.0/24
103.28.54.0/24
146.66.152.0/24
146.66.155.0/24
153.254.86.0/24
155.133.224.0/23
155.133.226.0/24
155.133.227.0/24
155.133.230.0/24
155.133.232.0/24
155.133.233.0/24
155.133.234.0/24
155.133.236.0/23
155.133.238.0/24
155.133.239.0/24
155.133.240.0/23
155.133.245.0/24
155.133.246.0/24
155.133.248.0/24
155.133.249.0/24
155.133.250.0/24
155.133.251.0/24
155.133.252.0/24
155.133.253.0/24
155.133.254.0/24
155.133.255.0/24
162.254.192.0/24
162.254.193.0/24
162.254.194.0/23
162.254.195.0/24
162.254.196.0/24
162.254.197.0/24
162.254.198.0/24
162.254.199.0/24
185.25.182.0/24
185.25.183.0/24
190.217.33.0/24
192.69.96.0/22
205.185.194.0/24
205.196.6.0/24
208.64.200.0/24
208.64.201.0/24
208.64.202.0/24
208.64.203.0/24
208.78.164.0/22'

# -------------------------------
# QUIC Rule
# -------------------------------

uci set passwall2.QUIC='shunt_rules'
uci set passwall2.QUIC.remarks='QUIC'
uci set passwall2.QUIC.port='443'
uci set passwall2.QUIC.network='udp'

# -------------------------------
# Shunt Node
# -------------------------------

uci set passwall2.myshunt='nodes'
uci set passwall2.myshunt.remarks='Shunt'
uci set passwall2.myshunt.type='Xray'
uci set passwall2.myshunt.protocol='_shunt'
uci set passwall2.myshunt.preproxy_enabled='0'
uci set passwall2.myshunt.write_ipset_direct='1'
uci set passwall2.myshunt.domainStrategy='IPOnDemand'
uci set passwall2.myshunt.domainMatcher='hybrid'
uci set passwall2.myshunt.enable_geoview_ip='1'

uci set passwall2.myshunt.DNS='_default'
uci set passwall2.myshunt.PrivateIPs='_direct'
uci set passwall2.myshunt.IRAN='_direct'
uci set passwall2.myshunt.DirectGame='_direct'
uci set passwall2.myshunt.QUIC='_default'

# -------------------------------
# Global Settings
# -------------------------------

ensure_anon_section global
ensure_anon_section global_forwarding
ensure_anon_section global_delay
ensure_anon_section global_haproxy

uci set passwall2.@global[0].enabled='1'
uci set passwall2.@global[0].node='myshunt'
uci set passwall2.@global[0].localhost_proxy='1'
uci set passwall2.@global[0].client_proxy='1'
uci set passwall2.@global[0].socks_enabled='0'
uci set passwall2.@global[0].acl_enable='0'
uci set passwall2.@global[0].direct_dns_protocol='auto'
uci set passwall2.@global[0].direct_dns_query_strategy='UseIPv4'
uci set passwall2.@global[0].remote_dns_protocol='tcp'
uci set passwall2.@global[0].remote_dns='8.8.8.8'
uci set passwall2.@global[0].remote_dns_query_strategy='UseIPv4'
uci set passwall2.@global[0].remote_dns_detour='remote'
uci set passwall2.@global[0].write_ipset_direct='1'
uci set passwall2.@global[0].dns_redirect='1'
uci set passwall2.@global[0].log_node='1'
uci set passwall2.@global[0].loglevel='error'

uci set passwall2.@global_forwarding[0].tcp_no_redir_ports='disable'
uci set passwall2.@global_forwarding[0].udp_no_redir_ports='disable'
uci set passwall2.@global_forwarding[0].tcp_redir_ports='1:65535'
uci set passwall2.@global_forwarding[0].udp_redir_ports='1:65535'
uci set passwall2.@global_forwarding[0].accept_icmp='0'
uci set passwall2.@global_forwarding[0].use_nft='1'
uci set passwall2.@global_forwarding[0].tcp_proxy_way='redirect'
uci set passwall2.@global_forwarding[0].ipv6_tproxy='0'
uci set passwall2.@global_forwarding[0].prefer_nft='1'

uci set passwall2.@global_haproxy[0].balancing_enable='0'

uci set passwall2.@global_delay[0].auto_on='0'
uci set passwall2.@global_delay[0].start_daemon='1'
uci set passwall2.@global_delay[0].start_delay='30'

uci commit passwall2

/etc/init.d/passwall2 restart >/dev/null 2>&1

echo -e "${GREEN}Freedom Passwall2 rules applied successfully.${NC}"
