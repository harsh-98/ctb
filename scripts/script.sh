#!/bin/bash
# export FABRIC_CFG_PATH=${PWD}
# export VERBOSE=false
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo $FABRIC_CFG_PATH
echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

CC_SRC_PATH="github.com/chaincode/ctb/"

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 org1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in org1 org2 browser; do
	    for peer in 0; do
	    # for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.${org} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		# exit 0
		echo
	    done
	done
}
## Create channel
echo "Creating channel..."
createChannel
## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 0 org1
echo "Updating anchor peers for org2..."
updateAnchorPeers 0 org2
updateAnchorPeers 0 browser

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode"
installChaincode 0 org1
installChaincode 0 org2
installChaincode 0 browser
# installChaincode 1 org1
# installChaincode 1 org2
# installChaincode 1 browser


# Instantiate chaincode on peer0.org2
echo "Instantiating chaincode on peer0.org2..."
instantiateChaincode 0 org1

# Invoke chaincode on peer0.org1 and peer0.org2
echo "Sending invoke transaction on peer0.org1 peer0.org2..."
# adding the first certificate for domain.com
sleep 4
chaincodeInvoke 0 org1 0 org2
sleep 4
chaincodeQuery 0 browser domain.com
exit 0

# adding a new certificate for domain.com while the current one is active
newChaincodeInvoke 0 org1 0 org2
sleep 2
chaincodeQuery 0 browser domain.com

# revoking the current certificate
revokeCertificate 0 org1 0 org2
sleep 2
chaincodeQuery 0 browser domain.com

# getting certificate history
queryHistory 0 browser domain.com

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
