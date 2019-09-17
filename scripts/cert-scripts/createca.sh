CA=$1
mkdir $CA
cd $CA
openssl req \
       -newkey rsa:2048 -nodes -keyout $CA.key \
       -x509 -days 365 -out $CA.crt -subj "$2"
openssl rsa -in  $ca.key -out rsa-$ca.key
cd ..

