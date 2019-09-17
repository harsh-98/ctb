# Generate ca

./createca.sh ca "/C=US/ST=New York/L=Brooklyn/O=Example Brooklyn Company/CN=ca.com"


# Doamin certificate

 ./issuecert.sh domain ca "/C=US/ST=New York/L=Brooklyn/O=Example Brooklyn Company/CN=domain.com" domain.com 

# Renew domain certificate

./issuecert.sh renew-domain ca "/C=US/ST=New York/L=Brooklyn/O=Example Brooklyn Company/CN=domain.com" domain.com
