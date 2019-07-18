
if [ -z $3 ]
then
echo "add_ip_sans.sh cakey cacert domain"
exit 0
fi
rm -rf a.pem req.pem
KEYPEM="$1"
CERTPEM="$2"
DOMAIN=$3
openssl req -new -sha256 -key server.key -out req.pem -subj "/C=US/ST=California/L=San Francisco/CN=$DOMAIN" -config ext.cnf
openssl x509 -req -in req.pem -CA $CERTPEM -CAkey $KEYPEM -CAcreateserial \
-out a.pem -days 1825 -sha256 -extensions v3_req -extfile ext.cnf
mv server.crt b.pem
mv a.pem server.crt