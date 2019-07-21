#!/bin/bash

SUCCESSCOUNT=0
LOCK=0

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
    NUM=${3:-1}
    NAME=$DOMAIN-$NUM
    mkdir $NAME
    echo "##########################################################"
    echo "Generating certificate for $NAME"
    echo "##########################################################"
    cd $NAME
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


push_cert() {
    DOMAIN=$1
    CA=$2
    NUM=${3:-1}
    NEWDOMAIN=$1-$NUM
    CURRENTDOMAIN=$1-$((NUM -1))

    echo "##########################################################"
    echo "Pushing certificate for $NEWDOMAIN"
    echo "##########################################################"

    cert_string="$(sed ':a;N;$!ba;s/\n/\\n/g' $NEWDOMAIN/$NEWDOMAIN.crt)\\n"
    intermed_cert=$(sed ':a;N;$!ba;s/\n/\\n/g' $CA/$CA.crt)

    if [ $NUM -ne 1 ]
    then
    CMDSTRING="./sign without_pass $CURRENTDOMAIN/rsa-$CURRENTDOMAIN.key $NEWDOMAIN/$NEWDOMAIN.crt"
    echo -n > $NEWDOMAIN/sig
    echo "##########################################################"
    echo "Runnning $CMDSTRING"
    echo "##########################################################"

    sig_string=`$CMDSTRING`
    else
    sig_string=""
    fi

    echo -n $sig_string> $NEWDOMAIN/sig

    while [ $LOCK == 1 ]
    do
    echo -n ""
    done

    LOCK=1
    if [[ $response == *"submitted"* ]]; then
        SUCCESSCOUNT=$(($SUCCESSCOUNT + 1))
    fi
    LOCK=0

    echo
}

revoke_cert() {
    DOMAIN=$1
    CA=$2
    NUM=${3:-1}
    DOMAIN=$1-$NUM

    echo "##########################################################"
    echo "Revoking certificate for $NEWDOMAIN"
    echo "##########################################################"

    cert_string="$(sed ':a;N;$!ba;s/\n/\\n/g' $DOMAIN/$DOMAIN.crt)\\n"
    intermed_cert=$(sed ':a;N;$!ba;s/\n/\\n/g' $CA/$CA.crt)

    CMDSTRING="./sign without_pass $CA/rsa-$CA.key $DOMAIN/$DOMAIN.crt"
    echo "##########################################################"
    echo "Runnning $CMDSTRING"
    echo "##########################################################"

    sig_string=`$CMDSTRING`
    echo -n $sig_string > $DOMAIN/sig

    while [ $LOCK == 1 ]
    do
        echo -n ""
    done
    LOCK=1
    if [[ $response == *"submitted"* ]]; then
        SUCCESSCOUNT=$(($SUCCESSCOUNT + 1))
    fi
    LOCK=0

    echo
}

clean() {
    rm -rf `ls -d */`
}

test_domain() {
    CA=$2
    issue_cert $DOMAIN $CA
    push_cert $DOMAIN $CA
    for j in $(seq 2 $3)
        do
            issue_cert $DOMAIN $CA $j
            push_cert $DOMAIN $CA $j
        done
    revoke_cert $DOMAIN $CA $3

    if [ $i == $DOMAINCOUNT ]
    then
        echo "Success count is $SUCCESSCOUNT"
        RES=$(($ISSUECOUNT+1))
        echo "Request count is $(( $DOMAINCOUNT * $RES ))"
    fi
}

while getopts "h?c:d:n:i:or" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
    c) CA=$OPTARG
    ;;
    d)  URL=$OPTARG
    ;;
    n)  DOMAINCOUNT=$OPTARG
    ;;
    i)  ISSUECOUNT=$OPTARG
    ;;
    o)  ONLY_DOMAINS=true
    ;;
    r)  REMOVE_ALL=true
    ;;
  esac
done

function get_domain(){
    IFS='.' read -ra DOMAIN_A <<< $URL
    SUB="${DOMAIN_A[0]}$1"
    ROOT=$(printf ".%s" "${DOMAIN_A[@]:1:2}")
    echo "$SUB$ROOT"
}

main() {
    if [ $REMOVE_ALL -a ! $ONLY_DOMAINS ]
    then
        mv $CA ..
        clean
        mv ../$CA .
    fi

    if [ $REMOVE_ALL ]
    then
        clean
    fi

    if [ ! $ONLY_DOMAINS ]
    then
        create_ca $CA
    fi

    for i in $(seq 1 $DOMAINCOUNT)
        do
            DOMAIN=$(get_domain $i)
            echo $DOMAIN
            test_domain $i $CA $ISSUECOUNT
            # test_domain $i $CA $ISSUECOUNT  &
        done
}

main
