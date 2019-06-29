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

    openssl x509 -req -in $NAME.csr -CA ../$CA/$CA.crt -CAkey ../$CA/$CA.key -CAcreateserial \
    -out $NAME.crt -days 1825 -sha256 -extfile $NAME.ext

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
    curl localhost:8000/invoke -H "Content-Type: application/json" -d  "{\"cert_string\": \"$cert_string\",\"intermed_cert\": \"$intermed_cert\",\"sig_string\": \"$sig_string\"}"
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
    curl localhost:8000/invoke -H "Content-Type: application/json" -d  "{\"cert_string\": \"$cert_string\",\"intermed_cert\": \"$intermed_cert\",\"sig_string\": \"$sig_string\",\"revoke\": \"true\"}"
    echo
}

clean() {
    rm -rf `ls -d */`
}

main(){
    clean
    CA=ca.or.example.com
    create_ca $CA
    for i in {1..1}
        do
            DOMAIN=tst$i.example.com
            issue_cert $DOMAIN $CA
            push_cert $DOMAIN $CA

            for j in {2..2}
                do
                    issue_cert $DOMAIN $CA $j
                    push_cert $DOMAIN $CA $j
                done

            revoke_cert $DOMAIN $CA 2
        done
}

main