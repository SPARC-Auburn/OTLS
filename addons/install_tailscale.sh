#!/usr/bin/env bash
set -euo pipefail
if [ -z "${TS_AUTHKEY:-}" ]; then
  echo "Set TS_AUTHKEY env var before running (ephemeral or reusable)."; exit 1
fi
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=${TS_AUTHKEY} --advertise-tags=otls --ssh --accept-routes
tailscale status
