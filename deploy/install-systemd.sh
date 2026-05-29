#!/bin/bash
# 在 Ubuntu 宿主机上执行一次（需要 sudo）
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_PATH="/opt/deployments"

sudo mkdir -p "${DEPLOY_PATH}"
sudo chown ubuntu:ubuntu "${DEPLOY_PATH}"
sudo cp "${SCRIPT_DIR}/demo-app.service" /etc/systemd/system/
sudo cp "${SCRIPT_DIR}/demo-app-restart.service" /etc/systemd/system/
sudo cp "${SCRIPT_DIR}/demo-app.path" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable demo-app.path
sudo systemctl enable demo-app.service
sudo systemctl restart demo-app.path

echo ""
echo "=== 安装结果 ==="
systemctl is-active demo-app.path
systemctl is-enabled demo-app.path
systemctl is-enabled demo-app.service

echo ""
echo "说明："
echo "  - demo-app.service 的日志写在 ${DEPLOY_PATH}/app.log，不在 journalctl"
echo "  - 部署时 Jenkins 会 touch restart.flag 触发重启"
echo "  - 手动测试：rm -f ${DEPLOY_PATH}/restart.flag && touch ${DEPLOY_PATH}/restart.flag"
