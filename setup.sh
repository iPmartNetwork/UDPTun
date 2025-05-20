#!/bin/bash

REPO_URL="https://github.com/iPmartNetwork/udptun.git"
TARGET_DIR="/opt/udptun"
MANAGER_SCRIPT="udptun.sh"

echo "==== UDP Tunnel Auto Installer ===="

# Check for git
if ! command -v git >/dev/null 2>&1; then
    echo "[*] Installing git..."
    apt update && apt install -y git
fi

# Remove any previous install
if [ -d "$TARGET_DIR" ]; then
    echo "[*] Removing previous install in $TARGET_DIR"
    rm -rf "$TARGET_DIR"
fi

echo "[*] Cloning repository..."
git clone "$REPO_URL" "$TARGET_DIR"
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to clone repository from $REPO_URL"
    exit 1
fi

cd "$TARGET_DIR" || { echo "[ERROR] Cannot cd to $TARGET_DIR"; exit 2; }

if [ ! -f "$MANAGER_SCRIPT" ]; then
    echo "[ERROR] $MANAGER_SCRIPT not found in $TARGET_DIR"
    exit 3
fi

chmod +x "$MANAGER_SCRIPT"

echo "---------------------------------------------"
echo "[*] Running UDP Tunnel Manager..."
echo "---------------------------------------------"
sudo ./$MANAGER_SCRIPT
