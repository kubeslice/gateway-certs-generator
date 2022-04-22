#!/bin/bash


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

########################
# Source Required Scripts
#########################
. ./ovpn/scripts/initialize.sh
. ./ovpn/scripts/setEnv.sh
. ./ovpn/scripts/validate.sh
. ./ovpn/scripts/process.sh

init

validateInput

printParams

# All parameters satisfied, begin the work.
echo Generating OVPN Configuration

# Prepare environment
prepareExecution

# Initialize the directory structure
initPkiDirectory
# FIXME: should this be called if only pki does not exist? Stops the application flow if exists
# Get the previously generated assets
#
# getCertsFromS3
# Generate dh.pem if it doesn't already exist
generateDhPemFileIfMissing
##
# Generate the ta.key if it doesn't already exist
generateTaKeyFileIfMissing
##
# Generate the CA cert & key if they don't already exist
generateCaCertsIfMissing
#
## loop begins here
iterateCertPairRequest processIndividualCertRequest
## loop ends here

#updateSliceGatewayCRD
# ... and done!
./generator
#completeCleanup
#todo: enable clean up after verification
