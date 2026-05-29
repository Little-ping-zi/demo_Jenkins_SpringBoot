#!/bin/bash
# 在 Ubuntu 宿主机上执行一次（需要 sudo）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_PATH="/opt/deployments"

sudo mkdir -p "${DEPLOY_PATH}"
sudo cp "${SCRIPT_DIR}/demo-app.service" /etc/systemd/system/
sudo cp "${SCRIPT_DIR}/demo-app-restart.service" /etc/systemd/system/
sudo cp "${SCRIPT_DIR}/demo-app.path" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable demo-app.path
sudo systemctl enable demo-app.service
sudo systemctl start demo-app.path

echo "systemd units installed. Jenkins can deploy by copying the jar and touching restart.flag."
