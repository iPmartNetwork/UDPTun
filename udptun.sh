#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

check_command() {
    command -v "$1" >/dev/null 2>&1
}

install_requirements() {
    if ! check_command python3; then
        echo -e "${YELLOW}[*] Installing Python3...${NC}"
        apt update && apt install -y python3 python3-pip
    fi
    pip3 install --upgrade pip
}

show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════╗"
    echo -e "║      ${GREEN}UDP Tunnel VPN Manager${CYAN}        ║"
    echo -e "╠════════════════════════════════════╣"
    echo -e "║ 1) Start as Server                ║"
    echo -e "║ 2) Start as Client                ║"
    echo -e "║ 3) Stop All Tunnels               ║"
    echo -e "║ 4) Show Tunnel Status             ║"
    echo -e "║ 5) Exit                           ║"
    echo -e "╚════════════════════════════════════╝${NC}"
    echo -ne "${YELLOW}Select option [1-5]: ${NC}"
}

run_server() {
    read -p "Enter Listen Port [e.g. 1111]: " PORT
    read -p "Enter Local Tunnel IP [e.g. 192.168.128.1]: " LOCALIP
    read -p "Enter Peer Tunnel IP [e.g. 192.168.128.2]: " PEERIP
    echo -e "${GREEN}[*] Starting UDP Tunnel in Server mode...${NC}"
    nohup python3 udptun.py --server "$PORT" --local "$LOCALIP" --peer "$PEERIP" > udptun-server.log 2>&1 &
    echo $! > udptun-server.pid
    echo -e "${CYAN}Server started with log: udptun-server.log${NC}"
}

run_client() {
    read -p "Enter Server IP [e.g. 1.2.3.4]: " SERVERIP
    read -p "Enter Server Port [e.g. 1111]: " SERVERPORT
    read -p "Enter Local Tunnel IP [e.g. 192.168.128.2]: " LOCALIP
    read -p "Enter Peer Tunnel IP [e.g. 192.168.128.1]: " PEERIP
    echo -e "${GREEN}[*] Starting UDP Tunnel in Client mode...${NC}"
    nohup python3 udptun.py --client "$SERVERIP:$SERVERPORT" --local "$LOCALIP" --peer "$PEERIP" > udptun-client.log 2>&1 &
    echo $! > udptun-client.pid
    echo -e "${CYAN}Client started with log: udptun-client.log${NC}"
}

stop_tunnels() {
    for pidfile in udptun-server.pid udptun-client.pid; do
        if [ -f "$pidfile" ]; then
            kill "$(cat "$pidfile")" 2>/dev/null && echo -e "${YELLOW}Stopped tunnel process PID $(cat $pidfile)${NC}"
            rm -f "$pidfile"
        fi
    done
}

status_tunnels() {
    for pidfile in udptun-server.pid udptun-client.pid; do
        if [ -f "$pidfile" ]; then
            PID=$(cat "$pidfile")
            if ps -p $PID > /dev/null; then
                echo -e "${GREEN}Tunnel running (PID: $PID, Log: udptun-$(basename $pidfile .pid).log)${NC}"
            else
                echo -e "${RED}Tunnel PID file found but process not running (PID: $PID)${NC}"
            fi
        fi
    done
}

install_requirements

while true; do
    show_menu
    read opt
    case $opt in
        1) run_server ;;
        2) run_client ;;
        3) stop_tunnels ;;
        4) status_tunnels ;;
        5) echo -e "${YELLOW}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac
    echo -e "${YELLOW}Press Enter to return to menu...${NC}"
    read
done
