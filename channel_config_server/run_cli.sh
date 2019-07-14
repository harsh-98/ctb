#!/bin/bash
function getOriginalConfigTx () {
  echo
  echo "###############################################################"
  echo "####### Generate and submit config tx to add Org3 #############"
  echo "###############################################################"
  docker exec cli scripts/fetch_config.sh
  mkdir serve
  docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/config.json serve/
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to create config tx"
    exit 1
  fi
}
getOriginalConfigTx
