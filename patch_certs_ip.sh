#!/bin/bash
# if [ -z $3 ]
# then
# echo "add_ip_sans.sh cakey cacert domain"
# exit 0
# fi


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
    PEER_DIR=crypto-config/ordererOrganizations/example.com/orderers
    # getKeyAndCert crypto-config/ordererOrganizations/example.com/tlsca orderer
# exit 0
    for i in `ls crypto-config/peerOrganizations`
    do
        PEER_DIR=crypto-config/peerOrganizations/$i/peers
        getKeyAndCert crypto-config/peerOrganizations/$i/tlsca peer
    done
}


function patchCert(){
    PEER_DIR=$1
    PEER_TYPE=$2
    EXT_FILE_PATH="base/ext.cnf"
    EXT_CONTENT=`cat $EXT_FILE_PATH`
    for PEER in `ls $PEER_DIR`
    do
        CERT_PATH="$PEER_DIR/$PEER/tls"
        if [ ! -d $CERT_PATH ]
        then
         continue
        fi

        echo "########################################"
        echo $PEER
        echo "Path is $CERT_PATH"
        echo "########################################"

        openssl req -new -sha256 -key $CERT_PATH/server.key -out $CERT_PATH/req.pem -subj "/C=US/ST=California/L=San Francisco/CN=$PEER"

        cat <(cat $EXT_FILE_PATH <(echo IP=$ORG_IP ; echo DNS=$PEER ; echo DNS.1=$PEER_TYPE))

        # echo <(echo $EXT_CONTENT)
        openssl x509 -req -in $CERT_PATH/req.pem -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial \
            -out $CERT_PATH/a.pem -days 1825 -sha256 -extensions v3_req -extfile <(cat $EXT_FILE_PATH <(echo IP=$ORG_IP ; echo DNS=$PEER ; echo DNS.1=$PEER_TYPE))

        cd $CERT_PATH
        mv server.crt b.pem
        mv a.pem server.crt
        cd $CWD
        echo
        echo
        exit 0

    done
}

patchOrdererAndOrgs