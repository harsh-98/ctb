#!/bin/bash
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

COUNT_NAME=
MSP_NAME=
ORG_NAME=
ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" == "Darwin" ]; then
  OPTS="-it"
else
  OPTS="-i"
fi

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  eyfn.sh up|down|restart|generate [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>]"
  echo "  eyfn.sh -h|--help (print this message)"
  echo "    <mode> - one of 'up', 'down', 'restart' or 'generate'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "    -c <channel name> - channel name to use (defaults to \"mychannel\")"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -f <docker-compose-file> - specify which docker-compose file use (defaults to docker-compose-cli.yaml)"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -l <language> - the chaincode language: golang (default) or node"
  echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
  echo "    -v - verbose mode"
  echo
  echo "Typically, one would first generate the required certificates and "
  echo "genesis block, then bring up the network. e.g.:"
  echo
  echo "	eyfn.sh generate -c mychannel"
  echo "	eyfn.sh up -c mychannel -s couchdb"
  echo "	eyfn.sh up -l node"
  echo "	eyfn.sh down -c mychannel"
  echo
  echo "Taking all defaults:"
  echo "	eyfn.sh generate"
  echo "	eyfn.sh up"
  echo "	eyfn.sh down"
}

. ../scripts/common-utils.sh



# Generate the needed certificates, the genesis block and start the network.
function networkUp () {
  # generate artifacts if they don't exist

  for i in `ls docker-compose-deploy-*yaml`
  do
    IMAGE_TAG=$IMAGETAG docker-compose -f $i up -d 2>&1
  done

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start Org3 network"
    exit 1
  fi
  echo
  echo "###############################################################"
  echo "############### Have New Org peers join network ##################"
  echo "###############################################################"
  # docker exec Org3cli ./scripts/step2org3.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
  # if [ $? -ne 0 ]; then
  #   echo "ERROR !!!! Unable to have Org3 peers join network"
  #   exit 1
  # fi
  # # finish by running the test
  # docker exec Org3cli ./scripts/testorg3.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
  # if [ $? -ne 0 ]; then
  #   echo "ERROR !!!! Unable to run test"
  #   exit 1
  # fi
}

# Tear down running network
function networkDown () {

  for i in `ls docker-compose-deploy-*yaml`
  do
    docker-compose -f $i down --volumes --remove-orphans
  done

  # Don't remove containers, images, etc if restarting
  if [ "$MODE" != "restart" ]; then
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    # remove the docker-compose yaml file that was customized to the example
  fi
}

# Use the CLI container to create the configuration transaction needed to add
# Org3 to the network
function createConfigTx () {
  echo
  echo "###############################################################"
  echo "####### Generate and submit config tx to add Org3 #############"
  echo "###############################################################"
  docker exec cli scripts/step1org3.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to create config tx"
    exit 1
  fi
}


# Generate channel configuration transaction
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  echo "##########################################################"
  echo "#########  Generating New Org config material ###############"
  echo "##########################################################"
  mkdir -p channel-artifacts
  export FABRIC_CFG_PATH=$PWD
  set -x
  configtxgen -printOrg ${MSP_NAME}MSP > channel-artifacts/org3.json
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate Org3 config material..."
    exit 1
  fi

  # cp -r ../crypto-config/ordererOrganizations crypto-config/
}


# If BYFN wasn't run abort
if [ ! -d crypto-config ]; then
  echo
  echo "ERROR: Please, run byfn.sh first."
  echo
  exit 1
fi

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
#default for delay
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# use this as the default docker-compose yaml definition
# kafka and zookeeper compose file
COMPOSE_FILE_KAFKA=docker-compose-kafka.yaml
# two additional etcd/raft orderers
COMPOSE_FILE_RAFT2=docker-compose-etcdraft2.yaml
# use golang as the default language for chaincode
LANGUAGE=golang
# default image tag
IMAGETAG="latest"

# Parse commandline args
if [ "$1" = "-m" ];then	# supports old usage, muscle memory is powerful!
    shift
fi
MODE=$1;shift
# Determine whether starting, stopping, restarting or generating for announce
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
elif [ "$MODE" == "restart" ]; then
  EXPMODE="Restarting"
elif [ "$MODE" == "clean" ]; then
  EXPMODE="clean"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and genesis block for"
else
  printHelp
  exit 1
fi
while getopts "h?c:t:d:f:s:l:i:v" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    c)  CHANNEL_NAME=$OPTARG
    ;;
    t)  CLI_TIMEOUT=$OPTARG
    ;;
    d)  CLI_DELAY=$OPTARG
    ;;
    f)  COMPOSE_FILE=$OPTARG
    ;;
    s)  IF_COUCHDB=$OPTARG
    ;;
    l)  LANGUAGE=$OPTARG
    ;;
    i)  IMAGETAG=$OPTARG
    ;;
    v)  VERBOSE=true
    ;;
  esac
done

function rmYaml(){
  rm -rf configtx.yaml crypto-config.yaml docker-compose-deploy-*.yaml channel-artifacts/* crypto-config/*
}

function setConstant(){
  mkdir channel-artifacts crypto-config
  COUNT_NAME=$1
  ORG_NAME=${2:-"org$COUNT_NAME"}
  MSP_NAME=${ORG_NAME^}
  COUNT_NAME=$(( $COUNT_NAME + 6))
}

function makeOrgYaml(){
  LOCALHOST=${1:-"127.0.0.1:"}

  local CURRENT_DIR=$PWD
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

function generateNewOrgYaml(){
  echo "##########################################################"
  echo "##### Generate yamlfiles for $MSP_NAME tool #########"
  echo "##########################################################"

  CRYPTO_FILENAME=crypto-config.yaml
  cp new-org-crypto.yaml $CRYPTO_FILENAME
  sed $OPTS "s/ORG_NAME/${ORG_NAME}/g" $CRYPTO_FILENAME
  sed $OPTS "s/MSP_NAME/${MSP_NAME}/g" $CRYPTO_FILENAME

  local FILENAME=configtx.yaml
  cp new-org-configtx.yaml $FILENAME
  sed $OPTS "s/COUNT_NAME/${COUNT_NAME}/g" $FILENAME
  sed $OPTS "s/ORG_NAME/${ORG_NAME}/g" $FILENAME
  sed $OPTS "s/MSP_NAME/${MSP_NAME}/g" $FILENAME

  local FILENAME=docker-compose-deploy-cli.yaml
  cp docker-compose-cli.yaml $FILENAME
  sed $OPTS "s/COUNT_NAME/${COUNT_NAME}/g" $FILENAME
  sed $OPTS "s/ORG_NAME/${ORG_NAME}/g" $FILENAME
  sed $OPTS "s/MSP_NAME/${MSP_NAME}/g" $FILENAME
}

askProceed
#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "clean" ]; then ## Clear the network
  rmYaml
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  setConstant 4
  generateNewOrgYaml
  generateCerts "./crypto-config.yaml"
  makeOrgYaml
  generateChannelArtifacts
  # createConfigTx
elif [ "${MODE}" == "restart" ]; then ## Restart the network
  networkDown
  networkUp
else
  printHelp
  exit 1
fi
