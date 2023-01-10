#!/bin/sh

#
# 	# Copyright (c) 2022 Avesha, Inc. All rights reserved. # # SPDX-License-Identifier: Apache-2.0
#
# 	# Licensed under the Apache License, Version 2.0 (the "License");
# 	# you may not use this file except in compliance with the License.
# 	# You may obtain a copy of the License at
#
# 	# http://www.apache.org/licenses/LICENSE-2.0
#
# 	# Unless required by applicable law or agreed to in writing, software
# 	# distributed under the License is distributed on an "AS IS" BASIS,
# 	# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 	# See the License for the specific language governing permissions and
# 	# limitations under the License.
#

function prepareExecution() {
  log "Preparing for execution..."
  mkdir -p ${WORK_DIR}/ovpn
  cp -r ${SRC_DIR}/ovpn/* ${WORK_DIR}/ovpn
  export EASYRSA_PASSIN=pass:${PASS_SALT}${PASSIN}${PASS_SALT}
  export EASYRSA_PASSOUT=pass:${PASS_SALT}${PASSOUT}${PASS_SALT}
  chmod +x ${WORK_DIR}/ovpn/easyrsa-v3.0.8/easyrsa
  log "All preparations were done."
}

# Expects a callback
function iterateCertPairRequest() {
  callback="$1"
  for encrow in $(echo "${CERT_GEN_REQUESTS}" | base64 -d | jq -r '.pairs[] | @base64'); do
    row="$(echo ${encrow} | base64 -d)"
    VPN_FQDN=$(echo ${row} | jq -r '.vpnFqdn')
    NSM_SERVER_NETWORK=$(echo ${row} | jq -r '.nsmServerNetwork')
    NSM_CLIENT_NETWORK=$(echo ${row} | jq -r '.nsmClientNetwork')
    NSM_MASK=$(echo ${row} | jq -r '.nsmMask')
    VPN_IP_2_CLIENT=$(echo ${row} | jq -r '.vpnIpToClient')
    VPN_NETWORK=$(echo ${row} | jq -r '.vpnNetwork')
    VPN_MASK=$(echo ${row} | jq -r '.vpnMask')
    SERVER_ID=$(echo ${row} | jq -r '.serverId')
    export SERVER_ID
    export VPN_FQDN
    CLIENT_ID=$(echo ${row} | jq -r '.clientId')
    $callback
  done
}

function initPkiDirectory() {
  log "Initializing PKI directory..."
  pushd ${WORK_DIR}/ovpn
  ${WORK_DIR}/ovpn/easyrsa-v3.0.8/easyrsa init-pki
  popd
  log "PKI directory initialization done."
}

#function getCertsFromS3() {
#  log "Getting existing certs from S3..."
#  export CERT_S3_PATH="s3://${S3_BUCKET}/${CUSTOMER_ID}/${SLICE_NAME}/ovpn/"
#  if [[ "${STACK}" == "dev" || "${STACK}" == "stg" ]]; then
#    export CERT_S3_PATH="s3://${S3_BUCKET}/${CUSTOMER_ID}/ovpn/"
#  fi
#  aws s3 sync "${CERT_S3_PATH}" ${WORK_DIR}/ovpn/
#  log "Certs fetched from S3."
#}

function generateDhPemFileIfMissing() {
  DH_PEM_FILE=${WORK_DIR}/ovpn/dh.pem
  if [[ ! -f "$DH_PEM_FILE" ]]; then
      log "Generating dh.pem file..."
      pushd ${WORK_DIR}/ovpn
      openssl dhparam --out dh.pem 2048
      popd
      log "dh.pem file generated."
  fi
}

function generateTaKeyFileIfMissing() {
  TA_KEY_FILE=${WORK_DIR}/ovpn/ta.key
  if [[ ! -f "$TA_KEY_FILE" ]]; then
      log "Generating ta.key file..."
      pushd ${WORK_DIR}/ovpn
      /usr/sbin/openvpn --genkey --secret ./ta.key
      popd
      log "ta.key file generated."
  fi
}

function generateCaCertsIfMissing() {
  CA_CERT_FILE=${WORK_DIR}/ovpn/pki/ca.crt
  CA_KEY_FILE=${WORK_DIR}/ovpn/pki/private/ca.key
  GEN_CA=NO
  if [[ ! -f "$CA_CERT_FILE" ]]; then
      GEN_CA=YES
  fi

  if [[ ! -f "$CA_KEY_FILE" ]]; then
      GEN_CA=YES
  fi

  if [[ "${GEN_CA}" == "YES" ]]; then
      log "Generating CA cert and key..."
      pushd ${WORK_DIR}/ovpn
      ${WORK_DIR}/ovpn/easyrsa-v3.0.8/easyrsa --batch --req-cn=AveshaCA build-ca
      popd
      log "CA cert and key generated."
  fi
}

#function copyKeysToS3() {
#  log "Copying the generated keys and certs to s3..."
#  pushd ${WORK_DIR}/ovpn
#    aws s3 cp ./dh.pem "${CERT_S3_PATH}/dh.pem"
#    aws s3 cp ./ta.key "${CERT_S3_PATH}/ta.key"
#    aws s3 sync ./pki "${CERT_S3_PATH}/pki"
#  popd
#  log "Certs and keys were dumped to S3."
#}

function prepareTemplate() {
  log "Preparing templates for individual cert request"
  pushd ${WORK_DIR}/ovpn
  mkdir ${VPN_FQDN}
  cp -r template/* ${VPN_FQDN}/
  popd
  log "Templates prepared for individual cert request"
}

function substituteTemplateParameters() {
  log "Substituting template parameters..."
  pushd ${WORK_DIR}/ovpn
  # Template files for iteration
  FILES="ccd client-openvpn-combined.conf server-openvpn.conf ovpn_env.sh"

  # Multi-line file substitution
  for file in ${FILES}
  do
    sed -i -e "/<ca-cert>/r ${CA_CERT}" -e "//d" ${VPN_FQDN}/$file
    sed -i -e "/<client-cert>/r ${CLIENT_CERT}" -e "//d" ${VPN_FQDN}/$file
    sed -i -e "/<client-key>/r ${CLIENT_KEY}" -e "//d" ${VPN_FQDN}/$file
    sed -i -e "/<ta-key>/r ${TA_KEY}" -e "//d" ${VPN_FQDN}/$file
  done

  # Single-line text substitution
  for file in ${FILES}
  do
    sed -i "s;<vpn-fqdn>;${VPN_FQDN};g" ${VPN_FQDN}/$file
    sed -i "s;<logging>;${LOGGING};g" ${VPN_FQDN}/$file
    sed -i "s;<nsm-server-network>;${NSM_SERVER_NETWORK};g" ${VPN_FQDN}/$file
    sed -i "s;<nsm-client-network>;${NSM_CLIENT_NETWORK};g" ${VPN_FQDN}/$file
    sed -i "s;<nsm-mask>;${NSM_MASK};g" ${VPN_FQDN}/$file
    sed -i "s;<vpn-ip-2-client>;${VPN_IP_2_CLIENT};g" ${VPN_FQDN}/$file
    sed -i "s;<vpn-network>;${VPN_NETWORK};g" ${VPN_FQDN}/$file
    sed -i "s;<vpn-mask>;${VPN_MASK};g" ${VPN_FQDN}/$file
  done
  popd
  log "All parameters were substituted."
}

function generateServerCerts() {
  log "Generating server certs..."
  pushd ${WORK_DIR}/ovpn
  ${WORK_DIR}/ovpn/easyrsa-v3.0.8/easyrsa --batch --req-cn=${SERVER_ID} gen-req ${SERVER_ID} nopass
  ${WORK_DIR}/ovpn/easyrsa-v3.0.8/easyrsa --batch --req-cn=${SERVER_ID} sign-req server ${SERVER_ID}
  popd
  log "Server certs generated."
}

function generateClientCerts() {
  log "Generating client certs..."
  log "clientid.."
  echo "$CLIENT_ID"
  pushd ${WORK_DIR}/ovpn
  ${WORK_DIR}/ovpn/easyrsa-v3.0.8/easyrsa --batch --req-cn=${CLIENT_ID} gen-req ${CLIENT_ID} nopass
  ${WORK_DIR}/ovpn/easyrsa-v3.0.8/easyrsa --batch --req-cn=${CLIENT_ID} sign-req client ${CLIENT_ID}
  popd
  log "Client certs generated."
}

function generateServerTarball() {
  log "Building tarball..."
  mkdir ${WORK_DIR}/ovpn/tarball
  mkdir ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}
  mkdir ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/ccd
  mkdir ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki
  mkdir ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki/issued
  mkdir ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki/private

  cp ${WORK_DIR}/ovpn/${VPN_FQDN}/ccd ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/ccd/${CLIENT_ID}
  cp ${WORK_DIR}/ovpn/${VPN_FQDN}/server-openvpn.conf ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/openvpn.conf
  cp ${WORK_DIR}/ovpn/${VPN_FQDN}/ovpn_env.sh ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/ovpn_env.sh
  cp ${WORK_DIR}/ovpn/pki/issued/${SERVER_ID}.crt ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki/issued/${VPN_FQDN}.crt
  cp ${WORK_DIR}/ovpn/pki/private/${SERVER_ID}.key ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki/private/${VPN_FQDN}.key
  cp ${WORK_DIR}/ovpn/pki/ca.crt ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki/ca.crt
  cp ${WORK_DIR}/ovpn/dh.pem ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki/dh.pem
  cp ${WORK_DIR}/ovpn/ta.key ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/pki/${VPN_FQDN}-ta.key

  pushd ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}
#  tar -czvf ${SERVER_ID}.tar *
  log "Tarball built."
  popd
}

function processIndividualCertRequest() {
  prepareTemplate
  # Generate Server Certs
  generateServerCerts
  # Generate Client Certs
  generateClientCerts
  # Source Client Cert Env Paths
  CLIENT_CERT=${WORK_DIR}/ovpn/pki/issued/${CLIENT_ID}.crt
  CLIENT_KEY=${WORK_DIR}/ovpn/pki/private/${CLIENT_ID}.key
  # Substitute template parameters
  substituteTemplateParameters
  # generate server tarball
  generateServerTarball
  # dump server tarball & client-combined.ovpn to s3 location
#  dumpClientAndServerArtifacts
  # append the callback output
  appendCallbackOutput
}

function dumpClientAndServerArtifacts() {
  log "Dumping server and client assets to S3..."
#  SERVER_S3_ASSET_URL="s3://${S3_BUCKET}/${CUSTOMER_ID}/${SLICE_NAME}/server/${SERVER_ID}/${VPN_FQDN}.tar"
#  CLIENT_S3_ASSET_URL="s3://${S3_BUCKET}/${CUSTOMER_ID}/${SLICE_NAME}/client/${CLIENT_ID}/${CLIENT_ID}-combined.ovpn"
#  aws s3 cp ${WORK_DIR}/ovpn/tarball/${VPN_FQDN}/${SERVER_ID}.tar ${SERVER_S3_ASSET_URL}
#  aws s3 cp ${WORK_DIR}/ovpn/${VPN_FQDN}/client-openvpn-combined.conf ${CLIENT_S3_ASSET_URL}
  log "Server and client assets dumped."
}

function appendCallbackOutput() {
  if [[ ! -z $CALLBACK_OUTPUT ]]; then
    CALLBACK_OUTPUT="${CALLBACK_OUTPUT},"
  fi
  CERT_OUTPUT='{"gatewayId": "<server-gatewayId>", "assetS3Url": "<server-s3-url>" }, { "gatewayId": "<client-gatewayId>", "assetS3Url": "<client-s3-url>"}'
  CERT_OUTPUT=$(echo $CERT_OUTPUT | sed "s;<server-gatewayId>;${SERVER_ID};g")
  CERT_OUTPUT=$(echo $CERT_OUTPUT | sed "s;<client-gatewayId>;${CLIENT_ID};g")
  CERT_OUTPUT=$(echo $CERT_OUTPUT | sed "s;<server-s3-url>;${SERVER_S3_ASSET_URL};g")
  CERT_OUTPUT=$(echo $CERT_OUTPUT | sed "s;<client-s3-url>;${CLIENT_S3_ASSET_URL};g")
  CALLBACK_OUTPUT="${CALLBACK_OUTPUT} ${CERT_OUTPUT}"
}

function completeCleanup() {
  log "Cleaning up..."
  rm -rf ${WORK_DIR}/ovpn
  log "Cleanup complete."
}