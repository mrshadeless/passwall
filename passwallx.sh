#!/bin/sh
# Freedom Passwall Custom Launcher
# Main entry point: sh passwallx.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
uci set system.@system[0].zonename='Asia/Tehran'
uci set system.@system[0].timezone='<+0330>-3:30'
uci commit system
/sbin/reload_config

. /etc/openwrt_release 2>/dev/null
MODEL="$(cat /tmp/sysinfo/model 2>/dev/null)"

echo -e "${YELLOW}
 ______ _____  ______ ______ _____   ____  __  __
|  ____|  __ \|  ____|  ____|  __ \ / __ \|  \/  |
| |__  | |__) | |__  | |__  | |  | | |  | | \  / |
|  __| |  _  /|  __| |  __| | |  | | |  | | |\/| |
| |    | | \ \| |____| |____| |__| | |__| | |  | |
|_|    |_|  \_\______|______|_____/ \____/|_|  |_|
${NC}"

echo " - Model      : ${MODEL:-Unknown}"
echo " - OpenWrt    : ${DISTRIB_RELEASE:-Unknown}"
echo " - Arch       : ${DISTRIB_ARCH:-Unknown}"
echo ""

if [ -f /etc/init.d/passwall2 ]; then
    echo -e "${YELLOW} 5.${NC} ${GREEN}Update Passwall2${NC}"
fi

echo -e "${YELLOW} 2.${NC} ${CYAN}Install Passwall2 / Freedom preset${NC}"
echo -e "${YELLOW} 6.${NC} ${RED}Exit${NC}"
echo ""

printf " Select option: "
read choice

case "$choice" in
    2)
        echo -e "${GREEN}Installing Passwall2 Freedom preset...${NC}"
        if [ -f ./passwall2x.sh ]; then
            sh ./passwall2x.sh
        else
            echo -e "${RED}passwall2x.sh not found in current directory.${NC}"
            exit 1
        fi
        ;;
    5)
        echo -e "${GREEN}Updating Passwall2...${NC}"
        opkg update && opkg install luci-app-passwall2 xray-core
        ;;
    6)
        echo -e "${GREEN}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option.${NC}"
        exit 1
        ;;
esac
