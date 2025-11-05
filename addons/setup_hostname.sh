#!/usr/bin/env bash
set -euo pipefail
HOST=${1:-otsl-chacaltaya}
sudo hostnamectl set-hostname "$HOST"
sudo apt-get update
sudo apt-get install -y avahi-daemon
echo "[hostname] Set to $HOST; .local discovery enabled (e.g., $HOST.local)"
