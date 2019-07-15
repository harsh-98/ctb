#!/bin/bash

CHANNEL_NAME="$1"
LANGUAGE="$2"
ORG_COUNT="$3"
VERSION="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${LANGUAGE:="golang"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5

CC_SRC_PATH="github.com/chaincode/ctb"

# import utils
. scripts/utils.sh

for i in $(seq 1 $(($ORG_COUNT -1)))
do
    ORG_NAME=org$i
    echo "===================== Installing chaincode $VERSION on peer0.$ORG_NAME ===================== "
    installChaincode 0 $ORG_NAME $VERSION
done

echo
echo "========= Finished installing chaincode on $ORG_COUNT organistaions ========= "
echo

exit 0