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

#########################
# Input Parameter Validation - Begin
#########################
function validateInput() {
  log "Validating input..."
  FAIL=NO

  if [[ -z ${NAMESPACE} ]]; then
    echo -e "NAMESPACE is missing\n"
    FAIL=YES
  fi

  if [[ -z ${SERVER_SLICEGATEWAY_NAME} ]]; then
    echo -e "SERVER_SLICEGATEWAY_NAME is missing\n"
    FAIL=YES
  fi
  if [[ -z ${CLIENT_SLICEGATEWAY_NAME} ]]; then
    echo -e "CLIENT_SLICEGATEWAY_NAME is missing\n"
    FAIL=YES
  fi


  if [[ -z ${SLICE_NAME} ]]; then
    echo -e "SLICE_NAME is missing\n"
    FAIL=YES
  fi

  if [[ -z ${CERT_GEN_REQUESTS} ]]; then
    echo -e "CERT_GEN_REQUESTS is missing\n"
    FAIL=YES
  fi

  if [[ "${FAIL}" == "YES" ]]; then
    log "One or more required parameters were missing."
    finish
    exit 1
  fi



  iterateCertPairRequest validateIndividualCertRequest

  log "All parameters were present."
}

function validateIndividualCertRequest() {
  FAIL=NO

  if [[ -z ${VPN_FQDN} ]]; then
    echo -e "VPN_FQDN is missing\n"
    FAIL=YES
  fi

  if [[ -z ${NSM_SERVER_NETWORK} ]]; then
    echo -e "NSM_SERVER_NETWORK is missing\n"
    FAIL=YES
  fi

  if [[ -z ${NSM_MASK} ]]; then
    echo -e "NSM_MASK is missing\n"
    FAIL=YES
  fi

  if [[ -z ${VPN_IP_2_CLIENT} ]]; then
    echo -e "VPN_IP_2_CLIENT is missing\n"
    FAIL=YES
  fi

  if [[ -z ${VPN_NETWORK} ]]; then
    echo -e "VPN_NETWORK is missing\n"
    FAIL=YES
  fi

  if [[ -z ${VPN_MASK} ]]; then
    echo -e "VPN_MASK is missing\n"
    FAIL=YES
  fi


  if [[ -z ${SERVER_ID} ]]; then
    echo -e "SERVER_ID is missing\n"
    FAIL=YES
  fi

  if [[ -z ${CLIENT_ID} ]]; then
    echo -e "CLIENT_ID is missing\n"
    FAIL=YES
  fi

  if [[ -z ${GATEWAY_PROTOCOL} ]]; then
    GATEWAY_PROTOCOL="udp"
  else
    GATEWAY_PROTOCOL=$(echo "${GATEWAY_PROTOCOL}" | tr '[:upper:]' '[:lower:]')
    if [[ ${GATEWAY_PROTOCOL} != "udp" && ${GATEWAY_PROTOCOL} != "tcp" ]]; then
      GATEWAY_PROTOCOL="udp"
    fi
  fi


  if [[ "${FAIL}" == "YES" ]]; then
    log "One or more required parameters were missing."
    finish
    exit 1
  fi
}

function printParams() {
  echo "Namespace: ${NAMESPACE}"
  echo "SERVER_SLICEGATEWAY_NAME: ${SERVER_SLICEGATEWAY_NAME}"
  echo "CLIENT_SLICEGATEWAY_NAME: ${CLIENT_SLICEGATEWAY_NAME}"
  echo "Slice Name: ${SLICE_NAME}"
  echo "VPN FQDN: ${VPN_FQDN}"
  echo "NSM Server Network: ${NSM_SERVER_NETWORK}"
  echo "NSM Network Mask: ${NSM_MASK}"
  echo "VPN IP to Client: ${VPN_IP_2_CLIENT}"
  echo "VPN Network: ${VPN_NETWORK}"
  echo "VPN Network Mask: ${VPN_MASK}"
}