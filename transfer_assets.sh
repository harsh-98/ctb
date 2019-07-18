

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  transfer_assets.sh <mode> [-v]"
  echo "    <mode> - one of 'connect' 'tlscert'"
  echo "      - 'connect' - send connect json "
  echo "      - 'tlscert' - tlscert required certificates and genesis block"
  echo
  echo "    -h - (print this message)"
  echo "    -f <FROM_IP> - number of orgs after upgrading network"
  echo "    -t <TO_IP> - version of chaincode to use"
  echo "    -p <FILE_PATH> - path of the file to transfer to TO_IP"
  echo "    -l <ARRAY>- array of peers tlscert to transfer from FROM_IP to TO_IP"

}

function pushOrdererAndOrgsTlsCert(){


    ORG_TLS_PATH=crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com
    pushCert tlsca.example.com-cert.pem
    for i in $ARRAY
    do
        ORG_TLS_PATH=crypto-config/peerOrganizations/$i.example.com/peers/peer0.$i.example.com
        echo $ORG_TLS_PATH
        pushCert tlsca.$i.example.com-cert.pem
    done
}

function pushCert(){
    CERT=$1
    rsync -avzhe  ssh --progress ctb@$FROM_IP:/home/ctb/ctb/$ORG_TLS_PATH/msp/tlscacerts/$CERT .
    ssh ctb@$TO_IP mkdir -p /home/ctb/ctb/$ORG_TLS_PATH/msp/tlscacerts/
    rsync -avzhe  ssh --progress $CERT ctb@$TO_IP:/home/ctb/ctb/$ORG_TLS_PATH/msp/tlscacerts/$CERT

}

function sendConnectJson(){
    rsync -avzhe  ssh --progress $1 ctb@$TO_IP:/home/ctb/ctb/server/ctb/connect.json

}

MODE=$1
shift

while getopts "h?f:t:p:l:" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
    f)  FROM_IP=$OPTARG
    ;;
    t)  TO_IP=$OPTARG
    ;;
    p)  FILE_PATH=$OPTARG
    ;;
    l)  ARRAY=$OPTARG
    ;;
  esac
done

echo $ARRAY



if [ "${MODE}" == "tlscert" ]; then
    pushOrdererAndOrgsTlsCert
elif [ "${MODE}" == "connect" ]; then
    sendConnectJson $FILE_PATH
fi