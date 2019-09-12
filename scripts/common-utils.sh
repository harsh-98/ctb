# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.mycc.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# TODO list generated image naming patterns
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.mycc.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}



# Versions of fabric known not to work with this release of first-network
BLACKLISTED_VERSIONS="^1\.0\. ^1\.1\.0-preview ^1\.1\.0-alpha"

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available.  In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {
  # Note, we check configtxlator externally because it does not require a config file, and peer in the
  # docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
  LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

  echo "LOCAL_VERSION=$LOCAL_VERSION"
  echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "=================== WARNING ==================="
    echo "  Local fabric binaries and docker images are  "
    echo "  out of  sync. This may cause problems.       "
    echo "==============================================="
  fi

  for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
      exit 1
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
      exit 1
    fi
  done
}

# Ask user for confirmation to proceed
function askProceed () {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
    y|Y|"" )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}

# We will use the cryptogen tool to generate the cryptographic material (x509 certs)
# for our various network entities.  The certificates are based on a standard PKI
# implementation where validation is achieved by reaching a common trust anchor.
#
# Cryptogen consumes a file - ``crypto-config.yaml`` - that contains the network
# topology and allows us to generate a library of certificates for both the
# Organizations and the components that belong to those Organizations.  Each
# Organization is provisioned a unique root certificate (``ca-cert``), that binds
# specific components (peers and orderers) to that Org.  Transactions and communications
# within Fabric are signed by an entity's private key (``keystore``), and then verified
# by means of a public key (``signcerts``).  You will notice a "count" variable within
# this file.  We use this to specify the number of peers per Organization; in our
# case it's two peers per Org.  The rest of this template is extremely
# self-explanatory.
#
# After we run the tool, the certs will be parked in a folder titled ``crypto-config``.

# Generates Org certs using cryptogen tool
function generateCerts() {
  which cryptogen
  rm -rf crypto-config
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  CRYPTOGEN_FILE=$1
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  # if [ -d "crypto-config" ]; then
  #   # rm -Rf crypto-config
  # fi
  set -x
  cryptogen generate --config=$CRYPTOGEN_FILE
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}


#####################################
#Certificate Patching and adding IP SANs
#####################################
# get ca key and cert
function getKeyAndCert(){
    CA_PATH=$1
    cd $CA_PATH

    CA_KEY="$CA_PATH/$(ls *_sk)"
    CA_CERT="$CA_PATH/$(ls *.pem)"

    cd $CWD
    patchCert $PEER_DIR $2
}

function patchOrdererAndOrgs(){
    CWD=$PWD
    echo $CWD
    EXT_FILE_PATH=$1
    PEER_DIR=crypto-config/ordererOrganizations/example.com/orderers
    getKeyAndCert crypto-config/ordererOrganizations/example.com/tlsca
# exit 0
    for i in `ls crypto-config/peerOrganizations`
    do
        PEER_DIR=crypto-config/peerOrganizations/$i/peers
        getKeyAndCert crypto-config/peerOrganizations/$i/tlsca
    done
}


function patchCert(){
    PEER_DIR=$1
    PEER_TYPE=$2
    EXT_CONTENT=`cat $EXT_FILE_PATH`
    for PEER in `ls $PEER_DIR`
    do
        CERT_PATH="$PEER_DIR/$PEER/tls"
        if [ ! -d $CERT_PATH ]
        then
         continue
        fi
        PEER_PREFIX=`echo $PEER | cut -f 1 -d "."`
        echo "########################################"
        echo $PEER
        echo "Path is $CERT_PATH"
        echo "########################################"

        openssl req -new -sha256 -key $CERT_PATH/server.key -out $CERT_PATH/req.pem -subj "/C=US/ST=California/L=San Francisco/CN=$PEER"



        # echo <(echo $EXT_CONTENT)
        openssl x509 -req -in $CERT_PATH/req.pem -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial \
            -out $CERT_PATH/a.pem -days 1825 -sha256 -extensions v3_req -extfile <(cat $EXT_FILE_PATH <(echo IP=$ORG_IP ; echo DNS=$PEER ; echo DNS.1=$PEER_PREFIX))

        cd $CERT_PATH
        mv server.crt b.pem
        mv a.pem server.crt
        cd $CWD
        echo
        echo

    done
}