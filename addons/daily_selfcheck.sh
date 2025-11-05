#!/usr/bin/env bash
# daily_selfcheck.sh — summarizes last 24h and sends via email/webhook
set -euo pipefail
CSV=${CSV_PATH:-/opt/otls/logs/otls_unified_log.csv}
OUT=/tmp/otls_daily_summary.txt
ALERT_TO=${ALERT_TO:-}
ALERT_FROM=${ALERT_FROM:-}
WEBHOOK_URL=${WEBHOOK_URL:-}
if [ -f /etc/default/otls ]; then source /etc/default/otls; fi
if [ ! -f "$CSV" ]; then
  echo "No CSV at $CSV" > "$OUT"
else
  NOW=$(date -u +%s)
  CUTOFF=$((NOW - 24*3600))
  count=0; fixes=0; nulls=0; last_ts=""
  while IFS=, read -r ts sys gnss fix sats pps drift pres t h bx by bz btot bstd notes; do
    [[ "$ts" == "Timestamp_UTC" ]] && continue
    sec=$(date -u -d "${ts%.*}Z" +%s 2>/dev/null || echo 0)
    if [ $sec -ge $CUTOFF ]; then
      count=$((count+1)); [[ "$fix" == "FIX" ]] && fixes=$((fixes+1)); [[ "$gnss" == "NULL" ]] && nulls=$((nulls+1))
      last_ts="$ts"
    fi
  done < "$CSV"
  {
    echo "OTSL Daily Self-Check (UTC)"
    echo "  Rows (24h):   $count"
    echo "  GNSS FIX rows:$fixes"
    echo "  GNSS NULLs:   $nulls"
    echo "  Last row:     ${last_ts:-none}"
  } > "$OUT"
fi
CONTENT=$(cat "$OUT")
if [ -n "$WEBHOOK_URL" ]; then
  curl -sS -X POST -H "Content-Type: application/json" -d "{\"text\":\"$CONTENT\"}" "$WEBHOOK_URL" >/dev/null || true
fi
if command -v msmtp >/dev/null 2>&1 && [ -n "$ALERT_TO" ]; then
  printf "Subject: OTSL Daily Self-Check\nFrom: %s\nTo: %s\n\n%s\n" "${ALERT_FROM:-otls@localhost}" "$ALERT_TO" "$CONTENT" | msmtp -t || true
fi
echo "$CONTENT"
