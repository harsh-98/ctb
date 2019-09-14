#!/bin/bash

create_ca(){
    echo "##########################################################"
    echo "Generating certificate for $CA"
    echo "##########################################################"
    mkdir $CA
    cd $CA
    openssl req \
        -newkey rsa:2048 -nodes -keyout $CA.key \
        -x509 -days 365 -out $CA.crt -subj "/C=HF/ST=HFCTB/L=CTB/O=cert transparency blockchain/CN=$CA"

    openssl rsa -in $CA.key -out rsa-$CA.key
    cd ..
}

issue_cert(){
    DOMAIN=$1
    CA=$2
    NUM=$3
    NAME=$DOMAIN
    mkdir $NAME$3
    echo "##########################################################"
    echo "Generating certificate for $NAME$3"
    echo "##########################################################"
    cd $NAME$3
    openssl req \
        -newkey rsa:2048 -nodes -keyout $NAME.key \
        -out $NAME.csr -subj "/C=HF/ST=HFCTB/L=CTB/O=cert transparency blockchain/CN=$DOMAIN"

    cp ../sample.ext $NAME.ext
    sed -i "s/domain.com/$DOMAIN/g" $NAME.ext

    while [ ! -s "$NAME.crt" ]
    do
        openssl x509 -req -in $NAME.csr -CA ../$CA/$CA.crt -CAkey ../$CA/$CA.key -CAcreateserial \
            -out $NAME.crt -days 1825 -sha256 -extfile $NAME.ext
    done

    openssl rsa -in $NAME.key -out rsa-$NAME.key
    cd ..
}


sign_cert() {
    DOMAIN=${1}1
    NEWDOMAIN=${1}2
    PREFIX=$1
    CA=$2
    echo "#####################################################################"
    echo "Signing new certificate for $PREFIX by $PREFIX's current private key"
    echo "#####################################################################"

    CMDSTRING="./sign without_pass $DOMAIN/rsa-$PREFIX.key $NEWDOMAIN/$PREFIX.crt"
    
    echo -n > $NEWDOMAIN/sig_by_domain
    sig_string=`$CMDSTRING`
    echo $sig_string > $NEWDOMAIN/sig_by_domain

    echo "#####################################################################"
    echo "Signing new certificate for $PREFIX by CA's private key"
    echo "#####################################################################"

    CMDSTRING="./sign without_pass $CA/rsa-$CA.key $NEWDOMAIN/$PREFIX.crt"
    
    echo -n > $NEWDOMAIN/sig_by_CA
    sig_string=`$CMDSTRING`
    echo $sig_string > $NEWDOMAIN/sig_by_CA

    rm sig
}

while getopts "h?c:d:" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
    c) CA=$OPTARG
    ;;
    d)  DOMAIN=$OPTARG
    ;;
  esac
done

main() {
	rm -r $CA
	rm -r ${DOMAIN}1
	rm -r ${DOMAIN}2
    create_ca $CA
    issue_cert $DOMAIN $CA 1
    issue_cert $DOMAIN $CA 2
    sign_cert $DOMAIN $CA
    rm -r ../scripts/certs/*
    cp -r ${PREFIX}1 ../scripts/certs/
    cp -r ${PREFIX}2 ../scripts/certs/
    cp -r $CA ../scripts/certs/
}

main
