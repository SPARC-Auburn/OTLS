#!/usr/bin/env bash
# sync_to_vm.sh — push logs to remote VM with rsync over SSH
set -euo pipefail
if [ -f /etc/default/otls ]; then source /etc/default/otls; fi
CSV_DIR=$(dirname "${CSV_PATH:-/opt/otls/logs/otls_unified_log.csv}")
if [ -z "${REMOTE_USER:-}" ] || [ -z "${REMOTE_HOST:-}" ] || [ -z "${REMOTE_PATH:-}" ]; then
  echo "[sync] REMOTE_* not configured in /etc/default/otls. Skipping."
  exit 0
fi
mkdir -p "$CSV_DIR"
rsync -avz --progress "$CSV_DIR/" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
