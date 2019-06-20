# Server/client HLCTB demo
This document provides a hands-on experience on testing HLCTB network for different X.509 certificate verfication scenarios. These scenarios are:

- while an active certificate is on HLCTB network
- a new certificate has been added to HLCTB network with consent of previous certificate
- the certificate for demo has been revoked.

This demo involves communication between 5 parties:
- HLCTB network
- CA authority
- query Server
- domain server
- client (browser)

## Creating the network
For generating crypto materials and channel configuration transactions,starting the members(docker images) of network and instantiating chaincode on channel.
```
./ctb.sh down <<< "Y" &&  ./ctb.sh generate <<< "Y" && ./ctb.sh up  <<< "Y"  && ./ctb.sh test <<< "Y"
```



### Enrolling admin and registering user
Removing previous keys and enrolling new one for admin, then registering user for org1:
```
cd server/
rm -rf wallet && node newadmin.js org1 && node newuser.js tester
```

## Flow 1
While an active certificate is on HLCTB network:

##### Adding certificate for domain.com
```
cd server
node newinvoke.js tester certs/domain.crt certs/ca.crt
```

##### Starting domain.com server
On a different terminal, from the root directory of this project:
```
cd test_app
node server.js ../scripts/certs/d2.key ../scripts/certs/d2.crt ../scripts/certs/ca.crt
```

##### Starting query server
On a different terminal, from root directory:
```
cd server
npm start
```

##### Connecting to domain.com server
```
cd test_app/client
node client.js ../../scripts/certs/ca.crt
```

After completing these steps, the response of client application should like the one given below. If the certificate for the domain is also present in the HLCTB network, the vertification is completed.
```
SSL PKI authenication status:  Success
Valid certificate: present on ctb network
```
Else  there is problem with the keys being used, or a new certificate has been issued or the current one has been revoked.

## Flow 2
A new certificate has been added to HLCTB network with consent of previous certificate:

##### Issue a new certificate
Issuing a new certificate with the consent of the domain, from the root directory of this project:
```
cd server
node newinvoke.js tester certs/d2.crt certs/ca.crt certs/sig-d2-by-domain
```
Here, the third argument is signature of d2.crt signed by private key of domain.crt pair.

##### Connect to domain.com server
```
cd test_app/client
node client.js ../../scripts/certs/ca.crt
```

If the response is similiar to below one, then the new certificate has been added. And Certificate for domain.com that we are using it client is on longer valid:
```
SSL PKI authenication status:  Success
invalid
```

##### Restart the domain.com server with updated certificate
From root directory:
```
cd test_app
node server.js ../scripts/certs/d2.key ../scripts/certs/d2.crt ../scripts/certs/ca.crt
```

##### Try reconnecting domain server
```
cd test_app/client
node client.js ../../scripts/certs/ca.crt
```
Reponse should match this:
```
SSL PKI authenication status:  Success
Valid certificate: present on ctb network
```
Hence the updated certificate is present on the HLCTB network.


## Flow 3

The certificate for demo has been revoked:

##### Connect to domain server
```
cd test_app/client
node client.js ../../scripts/certs/ca.crt
```

As the certificate is no longer valid, the response of client app shows that certificate is revoked.

```
SSL PKI authenication status:  Success
certificate has been revoked
```