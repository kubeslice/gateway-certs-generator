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

CA_CERT=${WORK_DIR}/ovpn/pki/ca.crt
TA_KEY=${WORK_DIR}/ovpn/ta.key


#VPN_FQDN=client1.vpn.aveshasystems.com
#LOGGING="status /etc/openvpn/openvpn-status.log"
# param
#NSM_CLIENT_IP=10.2.2.0
# param
#NSM_SERVER_IP=10.2.1.0
# param
#NSM_SERVER_IP_CIDR=10.2.1.0/24
# param
#NSM_SUBNET=255.255.255.0
# param
#VPN_IP=10.2.241.0
# param
#VPN_IP_2_CLIENT=10.2.241.2
# param
#VPN_IP_CIDR=10.2.241.0/24
# param
#VPN_SUBNET=255.255.255.0