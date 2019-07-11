#!/bin/bash
export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  ctb.sh <mode> [-v]"
  echo "    <mode> - one of 'up', 'down', 'restart', 'generate' or 'upgrade'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'test' - create channel and instantiate ctb chaincode"
  echo "      - 'make'  - generate org docker-compose file"
  echo "  ctb.sh -h (print this message)"
  echo
  echo "Operations: "
  echo "	ctb.sh generate"
  echo "	ctb.sh up"
  echo "	ctb.sh down"
  echo "	ctb.sh test"
  echo "	ctb.sh make"
}

. scripts/common-utils.sh





# Generate the needed certificates, the genesis block and start the network.
function networkUp() {
  checkPrereqs
  # generate artifacts if they don't exist
  if [ ! -d "crypto-config" ]; then
    # generateCerts "./crypto-config.yaml"
    # replacePrivateKey
    generateChannelArtifacts
  fi

  IMAGE_TAG=$IMAGETAG docker-compose -f docker-compose-cli.yaml up -d 2>&1
  for i in `ls docker-compose-deploy-*yaml`
  do
    IMAGE_TAG=$IMAGETAG docker-compose -f $i up -d 2>&1
  done
  docker ps -a

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi
}

function testcases(){
  # now run the end to end script
  docker exec cli scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
  fi
}

# Upgrade the network components which are at version 1.3.x to 1.4.x
# Stop the orderer and peers, backup the ledger for orderer and peers, cleanup chaincode containers and images
# and relaunch the orderer and peers with latest tag
function upgradeNetwork() {
  if [[ "$IMAGETAG" == *"1.4"* ]] || [[ $IMAGETAG == "latest" ]]; then
    docker inspect -f '{{.Config.Volumes}}' orderer.example.com | grep -q '/var/hyperledger/production/orderer'
    if [ $? -ne 0 ]; then
      echo "ERROR !!!! This network does not appear to start with fabric-samples >= v1.3.x?"
      exit 1
    fi

    LEDGERS_BACKUP=./ledgers-backup

    # create ledger-backup directory
    mkdir -p $LEDGERS_BACKUP

    export IMAGE_TAG=$IMAGETAG
    if [ "${IF_COUCHDB}" == "couchdb" ]; then
      if [ "$CONSENSUS_TYPE" == "kafka" ]; then
        COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_KAFKA -f $COMPOSE_FILE_COUCH"
      elif [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
        COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_RAFT2 -f $COMPOSE_FILE_COUCH"
      else
        COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH"
      fi
    else
      if [ "$CONSENSUS_TYPE" == "kafka" ]; then
        COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_KAFKA"
      elif [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
        COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_RAFT2"
      else
        COMPOSE_FILES="-f $COMPOSE_FILE"
      fi
    fi

    # removing the cli container
    docker-compose $COMPOSE_FILES stop cli
    docker-compose $COMPOSE_FILES up -d --no-deps cli

    echo "Upgrading orderer"
    docker-compose $COMPOSE_FILES stop orderer.example.com
    docker cp -a orderer.example.com:/var/hyperledger/production/orderer $LEDGERS_BACKUP/orderer.example.com
    docker-compose $COMPOSE_FILES up -d --no-deps orderer.example.com

    for PEER in peer0.org1.example.com peer1.org1.example.com peer0.org2.example.com peer1.org2.example.com; do
      echo "Upgrading peer $PEER"

      # Stop the peer and backup its ledger
      docker-compose $COMPOSE_FILES stop $PEER
      docker cp -a $PEER:/var/hyperledger/production $LEDGERS_BACKUP/$PEER/

      # Remove any old containers and images for this peer
      CC_CONTAINERS=$(docker ps | grep dev-$PEER | awk '{print $1}')
      if [ -n "$CC_CONTAINERS" ]; then
        docker rm -f $CC_CONTAINERS
      fi
      CC_IMAGES=$(docker images | grep dev-$PEER | awk '{print $1}')
      if [ -n "$CC_IMAGES" ]; then
        docker rmi -f $CC_IMAGES
      fi

      # Start the peer again
      docker-compose $COMPOSE_FILES up -d --no-deps $PEER
    done

    docker exec cli scripts/upgrade_to_v14.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
    if [ $? -ne 0 ]; then
      echo "ERROR !!!! Test failed"
      exit 1
    fi
  else
    echo "ERROR !!!! Pass the v1.4.x image tag"
  fi
}

# Tear down running network
function networkDown() {
  # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
  # stop kafka and zookeeper containers in case we're running with kafka consensus-type
  # docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_KAFKA -f $COMPOSE_FILE_RAFT2 down --volumes --remove-orphans
  docker-compose -f docker-compose-cli.yaml down --volumes --remove-orphans
  for i in `ls docker-compose-deploy-*yaml`
  do
    docker-compose -f $i down --volumes --remove-orphans
  done

  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    #Delete any ledger backups
    docker run -v $PWD:/tmp/first-network --rm hyperledger/fabric-tools:$IMAGETAG rm -Rf /tmp/first-network/ledgers-backup
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx ./org3-artifacts/crypto-config/ channel-artifacts/org3.json
  fi
}

function replaceUserPrivateKey() {
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and delete it at the end of the function
  FILENAME=$1
  EXT=$2
  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  # Copy the template to the file that will be modified to add the private key
  cp $FILENAME-sample.$EXT $FILENAME.$EXT

  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD

  cd crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/USER_PRIVATE_KEY/${PRIV_KEY}/g" $FILENAME.$EXT
  sed $OPTS "s_ROOTPATH_${PWD}_g" $FILENAME.$EXT

  cd crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/USER1_PRIVATE_KEY/${PRIV_KEY}/g" $FILENAME.$EXT

  cd crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/USER2_PRIVATE_KEY/${PRIV_KEY}/g" $FILENAME.$EXT

  cd crypto-config/peerOrganizations/browser.example.com/users/Admin@browser.example.com/msp/keystore/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/USER3_PRIVATE_KEY/${PRIV_KEY}/g" $FILENAME.$EXT

  # If MacOSX, remove the temporary backup of the docker-compose file
  if [ "$ARCH" == "Darwin" ]; then
    rm docker-compose-e2e.yamlt
  fi
}

function makeOrgYaml(){
  COUNT_NAME=$1
  ORG_NAME=${2:-"org$COUNT_NAME"}
  MSP_NAME=${ORG_NAME^}
  COUNT_NAME=$(( $COUNT_NAME + 6))
  local CURRENT_DIR=$PWD
  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi
  LOCALHOST=${3:-"127.0.0.1:"}

  local FILENAME=docker-compose-deploy-$ORG_NAME.yaml
  cp docker-compose-org-sample.yaml $FILENAME

  cd crypto-config/peerOrganizations/$ORG_NAME.example.com/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"

  sed $OPTS "s/CA_PRIVATE_KEY/${PRIV_KEY}/g" $FILENAME
  sed $OPTS "s/COUNT_NAME/${COUNT_NAME}/g" $FILENAME
  sed $OPTS "s/ORG_NAME/${ORG_NAME}/g" $FILENAME
  sed $OPTS "s/MSP_NAME/${MSP_NAME}/g" $FILENAME
  sed $OPTS "s/LOCALHOST/${LOCALHOST}/g" $FILENAME
}

# The `configtxgen tool is used to create four artifacts: orderer **bootstrap
# block**, fabric **channel configuration transaction**, and two **anchor
# peer transactions** - one for each Peer Org.
#
# The orderer block is the genesis block for the ordering service, and the
# channel transaction file is broadcast to the orderer at channel creation
# time.  The anchor peer transactions, as the name might suggest, specify each
# Org's anchor peer on this channel.
#
# Configtxgen consumes a file - ``configtx.yaml`` - that contains the definitions
# for the sample network. There are three members - one Orderer Org (``OrdererOrg``)
# and two Peer Orgs (``Org1`` & ``Org2``) each managing and maintaining two peer nodes.
# This file also specifies a consortium - ``SampleConsortium`` - consisting of our
# two Peer Orgs.  Pay specific attention to the "Profiles" section at the top of
# this file.  You will notice that we have two unique headers. One for the orderer genesis
# block - ``CTBOrdererGenesis`` - and one for our channel - ``CTBChannel``.
# These headers are important, as we will pass them in as arguments when we create
# our artifacts.  This file also contains two additional specifications that are worth
# noting.  Firstly, we specify the anchor peers for each Peer Org
# (``peer0.org1.example.com`` & ``peer0.org2.example.com``).  Secondly, we point to
# the location of the MSP directory for each member, in turn allowing us to store the
# root certificates for each Org in the orderer genesis block.  This is a critical
# concept. Now any network entity communicating with the ordering service can have
# its digital signature verified.
#
# This function will generate the crypto material and our four configuration
# artifacts, and subsequently output these files into the ``channel-artifacts``
# folder.
#
# If you receive the following warning, it can be safely ignored:
#
# [bccsp] GetDefault -> WARN 001 Before using BCCSP, please call InitFactories(). Falling back to bootBCCSP.
#
# You can ignore the logs regarding intermediate certs, we are not using them in
# this crypto implementation.

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  echo "CONSENSUS_TYPE="$CONSENSUS_TYPE
  set -x
  if [ "$CONSENSUS_TYPE" == "solo" ]; then
    configtxgen -profile CTBOrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
  elif [ "$CONSENSUS_TYPE" == "kafka" ]; then
    configtxgen -profile SampleDevModeKafka -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
  elif [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
    configtxgen -profile SampleMultiNodeEtcdRaft -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
  else
    set +x
    echo "unrecognized CONSESUS_TYPE='$CONSENSUS_TYPE'. exiting"
    exit 1
  fi
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile CTBChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org1MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile CTBChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org2MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile CTBChannel -outputAnchorPeersUpdate \
    ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org2MSP..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for BrowserMSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile CTBChannel -outputAnchorPeersUpdate \
    ./channel-artifacts/BrowserMSPanchors.tx -channelID $CHANNEL_NAME -asOrg BrowserMSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for BrowserMSP..."
    exit 1
  fi
  echo
}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
# default for delay between commands
CLI_DELAY=1
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# use this as the default docker-compose yaml definition
COMPOSE_FILE=docker-compose-cli.yaml
#
COMPOSE_FILE_COUCH=docker-compose-couch.yaml

# kafka and zookeeper compose file
COMPOSE_FILE_KAFKA=docker-compose-kafka.yaml
# two additional etcd/raft orderers
COMPOSE_FILE_RAFT2=docker-compose-etcdraft2.yaml
#
# use golang as the default language for chaincode
LANGUAGE=golang
# default image tag
IMAGETAG="latest"
# default consensus type
CONSENSUS_TYPE="solo"
# Parse commandline args
if [ "$1" = "-m" ]; then # supports old usage, muscle memory is powerful!
  shift
fi
MODE=$1
shift
# Determine whether starting, stopping, restarting, generating or upgrading
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and genesis block"
elif [ "$MODE" == "test" ]; then
  EXPMODE="running test case"
elif [ "$MODE" == "make" ]; then
  EXPMODE="Convert sample org to deployable org"
else
  printHelp
  exit 1
fi

while getopts "h?v" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  v)
    VERBOSE=true
    ;;
  esac
done


#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  # generateCerts "./crypto-config.yaml"
  makeOrgYaml 1 org1 0.0.0.0:
  makeOrgYaml 2
  makeOrgYaml 3 browser
  replaceUserPrivateKey "caliper/fabric" json
  generateChannelArtifacts
elif [ "${MODE}" == "test" ]; then ## Upgrade the network from version 1.2.x to 1.3.x
  testcases
elif [ "${MODE}" == "make" ]; then ## Upgrade the network from version 1.2.x to 1.3.x
  makeOrgYaml 1
else
  printHelp
  exit 1
fi
