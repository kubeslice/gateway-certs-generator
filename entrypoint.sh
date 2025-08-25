#!/bin/sh
set -e

echo "Gateway type: $GATEWAY_TYPE"

case "$GATEWAY_TYPE" in
  Wireguard)
    echo "Running WireGuard key generation"
    /app/wireguard/scripts/gen_key.sh
    ;;
  OpenVPN)
    echo "Running OpenVPN certificate generation"
    /app/generate-certs.sh
    ;;
  *)
    echo "Unknown GATEWAY_TYPE '$GATEWAY_TYPE'. Expected 'OpenVPN' or 'Wireguard'."
    exit 1
    ;;
esac