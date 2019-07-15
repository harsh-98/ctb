#!/bin/bash

CHANNEL_NAME="$1"
# import utils
. scripts/utils.sh

: ${CHANNEL_NAME:="mychannel"}
echo "Signing config transaction"
echo
signConfigtxAsPeerOrg org1 channel-artifacts/update_in_envelope.pb

echo
echo "========= Submitting transaction from a different peer (peer0.org2) which also signs it ========= "
echo
setGlobals 0 org2
set -x
peer channel update -f channel-artifacts/update_in_envelope.pb -c ${CHANNEL_NAME} -o orderer.example.com:7050 --tls --cafile ${ORDERER_CA}
set +x

exit 0