SUCCESSCOUNT=0
LOCK=0
DOMAINCOUNT=100
ISSUECOUNT=5


create_ca(){
    echo "##########################################################"
    echo "Generating certificate for $CA"
    echo "##########################################################"
    CA=$1
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
    echo "##########################################################"
    echo "Runnning $CMDSTRING"
    echo "##########################################################"

    sig_string=`$CMDSTRING`
    else
    sig_string=""
    fi

    echo "sig_string is $sig_string"
    local response=`curl localhost:8000/invoke/addCertificate -H "Content-Type: application/json" -d  "{\"certString\": \"$cert_string\",\"intermedCert\": \"$intermed_cert\",\"sigString\": \"$sig_string\",\"peer\": \"$NEWDOMAIN\"}"`

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
    echo "sig_string is $sig_string\n"
    local response=`curl localhost:8000/invoke/revokeCertificate -H "Content-Type: application/json" -d  "{\"certString\": \"$cert_string\",\"intermedCert\": \"$intermed_cert\",\"sigString\": \"$sig_string\",\"revoke\": \"true\",\"peer\": \"$DOMAIN\"}"`

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
    DOMAIN=iq$i.example.com
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


main() {
    clean
    CA=iq.example.com
    create_ca $CA
    for i in $(seq 1 $DOMAINCOUNT)
        do
            test_domain $i $CA $ISSUECOUNT  &
        done
}

main