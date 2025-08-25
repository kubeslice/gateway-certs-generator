#!/bin/sh

# Create WireGuard directory structure per VPN_FQDN
mkdir -p ${WORK_DIR}/wireguard/${VPN_FQDN}

# Generate Server keypair
wg genkey | tee ${WORK_DIR}/wireguard/${VPN_FQDN}/server_private.key | wg pubkey > ${WORK_DIR}/wireguard/${VPN_FQDN}/server_public.key

# Generate Client keypair
wg genkey | tee ${WORK_DIR}/wireguard/${VPN_FQDN}/client_private.key | wg pubkey > ${WORK_DIR}/wireguard/${VPN_FQDN}/client_public.key

./generator