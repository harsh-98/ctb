DOMAIN=$1
DOMAINNAME=${4:-$DOMAIN}
CA=$2
SUBJ=$3

mkdir $DOMAIN
cd $DOMAIN
openssl req \
       -newkey rsa:2048 -nodes -keyout $DOMAIN.key \
       -out $DOMAIN.csr -subj "$SUBJ"

cp ../sample.ext $DOMAIN.ext

sed -i "s/domain.com/$DOMAINNAME/g" $DOMAIN.ext

openssl x509 -req -in $DOMAIN.csr -CA ../$CA/$CA.crt -CAkey ../$CA/$CA.key -CAcreateserial \
-out $DOMAIN.crt -days 1825 -sha256 -extensions v3_req -extfile $DOMAIN.ext

openssl rsa -in $DOMAIN.key -out rsa-$DOMAIN.key

cd ..
