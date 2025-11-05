#!/usr/bin/env bash
# otls_healthcheck.sh — enhanced
set -euo pipefail
SERVICE=otls.service
CSV=${CSV_PATH:-/opt/otls/logs/otls_unified_log.csv}
ALERT_TO=${ALERT_TO:-}
ALERT_FROM=${ALERT_FROM:-}
WEBHOOK_URL=${WEBHOOK_URL:-}
STATE_DIR=/var/lib/otls
LOG_DIR=/var/log/otls
mkdir -p "$STATE_DIR" "$LOG_DIR"
if [ -f /etc/default/otls ]; then source /etc/default/otls; fi
ts() { date -Iseconds; }
log() { echo "[HC] $(ts) $*" | tee -a "$LOG_DIR/healthcheck.log"; }
alert() {
  MSG="$1"; log "ALERT: $MSG"
  if [ -n "$WEBHOOK_URL" ]; then
    curl -sS -X POST -H "Content-Type: application/json" -d "{\"text\":\"$MSG\"}" "$WEBHOOK_URL" >/dev/null || true
  fi
  if command -v msmtp >/dev/null 2>&1 && [ -n "$ALERT_TO" ]; then
    printf "Subject: OTSL Alert\nFrom: %s\nTo: %s\n\n%s\n" "${ALERT_FROM:-otls@localhost}" "$ALERT_TO" "$MSG" | msmtp -t || true
  fi
}
log "Checking $SERVICE ..."
if ! systemctl is-active --quiet "$SERVICE"; then
  alert "Service $SERVICE not active. Restarting..."; systemctl restart "$SERVICE" || true; sleep 5
fi
if [ -f "$CSV" ]; then
  MOD=$(date -r "$CSV" +%s); NOW=$(date +%s); AGE=$((NOW - MOD))
  if [ $AGE -gt 600 ]; then
    alert "CSV stale ($AGE s). Restarting service..."; systemctl restart "$SERVICE" || true
  else
    log "CSV fresh ($AGE s)."
  fi
else
  alert "CSV not found at $CSV. Creating directories and restarting."
  mkdir -p "$(dirname "$CSV")"; systemctl restart "$SERVICE" || true
fi
