#!/bin/bash

# Color Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_PATH/udptun.py"

# Check dependencies
function check_requirements() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] Installing python3...${NC}"
        apt update && apt install -y python3 python3-pip
    fi
    if ! python3 -c "import fcntl, pickle" 2>/dev/null; then
        echo -e "${YELLOW}[!] Installing required Python modules...${NC}"
        pip3 install --upgrade pip
    fi
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}You must run this script as root!${NC}"
        exit 1
    fi
}

# Build systemd service file
function build_service_file() {
    local mode="$1"  # server or client
    local name="$2"
    local cmd="$3"
    cat > /etc/systemd/system/udptun-$name.service <<EOF
[Unit]
Description=UDP Tunnel ($mode) - $name
After=network-online.target

[Service]
Type=simple
Restart=always
ExecStart=$cmd
WorkingDirectory=$SCRIPT_PATH
StandardOutput=append:$SCRIPT_PATH/udptun-$name.log
StandardError=append:$SCRIPT_PATH/udptun-$name.log

[Install]
WantedBy=multi-user.target
EOF
}

function start_server_service() {
    read -p "Port to listen on (e.g. 1111): " PORT
    read -p "Local tunnel IP (e.g. 192.168.128.1): " LOCALIP
    read -p "Peer tunnel IP (e.g. 192.168.128.2): " PEERIP
    local cmd="/usr/bin/python3 $PYTHON_SCRIPT --server $PORT --local $LOCALIP --peer $PEERIP"
    build_service_file "server" "server" "$cmd"
    systemctl daemon-reload
    systemctl enable --now udptun-server.service
    echo -e "${GREEN}[+] Server service started. Log: $SCRIPT_PATH/udptun-server.log${NC}"
}

function start_client_service() {
    read -p "Server IP (e.g. 1.2.3.4): " SERVERIP
    read -p "Server Port (e.g. 1111): " SERVERPORT
    read -p "Local tunnel IP (e.g. 192.168.128.2): " LOCALIP
    read -p "Peer tunnel IP (e.g. 192.168.128.1): " PEERIP
    local cmd="/usr/bin/python3 $PYTHON_SCRIPT --client $SERVERIP:$SERVERPORT --local $LOCALIP --peer $PEERIP"
    build_service_file "client" "client" "$cmd"
    systemctl daemon-reload
    systemctl enable --now udptun-client.service
    echo -e "${GREEN}[+] Client service started. Log: $SCRIPT_PATH/udptun-client.log${NC}"
}

function stop_service() {
    local name="$1"
    if systemctl is-active --quiet udptun-$name.service; then
        systemctl stop udptun-$name.service
        echo -e "${YELLOW}[!] $name service stopped.${NC}"
    else
        echo -e "${RED}[-] $name service is not running.${NC}"
    fi
}

function status_service() {
    local name="$1"
    systemctl status udptun-$name.service --no-pager
    if [[ -f $SCRIPT_PATH/udptun-$name.log ]]; then
        echo -e "${CYAN}--- Last 10 lines of $name log ---${NC}"
        tail -n 10 "$SCRIPT_PATH/udptun-$name.log"
        echo -e "${CYAN}-----------------------------${NC}"
    fi
}

function remove_service() {
    local name="$1"
    systemctl disable --now udptun-$name.service 2>/dev/null
    rm -f /etc/systemd/system/udptun-$name.service "$SCRIPT_PATH/udptun-$name.log"
    systemctl daemon-reload
    echo -e "${YELLOW}[!] $name service removed.${NC}"
}

function show_menu() {
    clear
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'
    WHITE='\033[1;37m'
    BLUE='\033[1;34m'

    echo -e "${BLUE}  ____________________________________________________________________________"
    echo -e "${BLUE}      ____                             _     _"
    echo -e "${BLUE} ,   /    )                           /|   /                                 "
    echo -e "${BLUE}-----/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__--"
    echo -e "${BLUE} /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) "
    echo -e "${BLUE}_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/____${NC}"

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║             ${GREEN}UDP Tunnel VPN Professional Manager${CYAN}           ║"
    echo -e "╠══════════════════════════════════════════════════════════════╣"
    echo -e "║ ${GREEN}1) Start as Server (systemd)${CYAN}                                 ║"
    echo -e "║ ${GREEN}2) Start as Client (systemd)${CYAN}                                 ║"
    echo -e "║ ${YELLOW}3) Show Server status/log${CYAN}                                    ║"
    echo -e "║ ${YELLOW}4) Show Client status/log${CYAN}                                    ║"
    echo -e "║ ${RED}5) Stop Server${CYAN}                                               ║"
    echo -e "║ ${RED}6) Stop Client${CYAN}                                               ║"
    echo -e "║ ${RED}7) Remove Server Service${CYAN}                                     ║"
    echo -e "║ ${RED}8) Remove Client Service${CYAN}                                     ║"
    echo -e "║ ${WHITE}9) Exit${CYAN}                                                      ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -ne "${YELLOW}Select option [1-9]: ${NC}"
}

}

check_requirements

while true; do
    show_menu
    read -r opt
    case $opt in
        1) start_server_service ;;
        2) start_client_service ;;
        3) status_service "server" ;;
        4) status_service "client" ;;
        5) stop_service "server" ;;
        6) stop_service "client" ;;
        7) remove_service "server" ;;
        8) remove_service "client" ;;
        9) echo -e "${YELLOW}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac
    echo -e "${YELLOW}Press Enter to return to menu...${NC}"
    read
done
