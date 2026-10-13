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
echo "      FREEDOM PASSWALL2 Status Page INSTALLER"
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

