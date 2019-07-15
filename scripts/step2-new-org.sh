#!/bin/bash

CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
ORG_NUM="$6"
ORG_NAME="org$ORG_NUM"
VERSION=$7
OPERATION=$8
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
PACKAGE_ID=""
CC_SRC_PATH="github.com/chaincode/ctb"

# import utils
. scripts/utils.sh

if [ $OPERATION == "install" ]
then
        echo "Fetching channel config block from orderer..."
        set -x
        peer channel fetch 0 $CHANNEL_NAME.block -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA >&log.txt
        # exit 0
        res=$?
        set +x
        cat log.txt
        verifyResult $res "Fetching config block from orderer has Failed"
        # joinChannelWithRetry 0 $ORG_NAME
        echo "===================== peer0.$ORG_NAME joined channel '$CHANNEL_NAME' ===================== "
        echo "Installing chaincode on peer0.$ORG_NAME"
        installChaincode 0 $ORG_NAME $VERSION
elif [ $OPERATION == "upgrade" ]
then
        echo "===================== Upgrading chaincode on peer0.$ORG_NAME ===================== "
        upgradeChaincode 0 $ORG_NAME $VERSION $ORG_NUM
fi

exit 0
