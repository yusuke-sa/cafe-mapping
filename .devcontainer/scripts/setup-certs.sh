#!/usr/bin/env bash
set -euo pipefail

# Import Cosmos Emulator self-signed cert so https requests succeed.
CERT_PATH=/usr/local/share/ca-certificates/cosmos-emulator.crt

echo "Fetching Cosmos Emulator certificate..."
if curl -k https://cosmos:8081/_explorer/emulator.pem -o "$CERT_PATH"; then
  echo "Updating CA certificates..."
  sudo update-ca-certificates || true
else
  echo "Warning: could not fetch Cosmos Emulator certificate. HTTPS calls may require NODE_TLS_REJECT_UNAUTHORIZED=0" >&2
fi
