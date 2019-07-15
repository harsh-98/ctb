#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run in the org3cli container as the
# first step of the EYFN tutorial.  It creates and submits a
# configuration transaction to add org3 to the network previously
# setup in the BYFN tutorial.
#

CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
ORG_NAME="$6"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5

# import utils
. scripts/utils.sh

echo
echo "========= Creating config transaction to add org3 to network =========== "
echo

# Fetch the config for the channel, writing it to config.json
wget 10.38.2.113:5000/config.json
# Modify the configuration to append the new org
set -x
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"'${ORG_NAME^}'MSP":.[1]}}}}}' config.json ./channel-artifacts/$ORG_NAME.json > modified_config.json
set +x

# Compute a config update, based on the differences between config.json and modified_config.json, write it as a transaction to update_in_envelope.pb
createConfigUpdate ${CHANNEL_NAME} config.json modified_config.json update_in_envelope.pb

echo
echo "========= Config transaction to add $ORG_NAME to network created ===== "

exit 0
