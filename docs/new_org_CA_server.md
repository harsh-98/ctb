# Adding CA server
After successfully adding new org(org3) to network and patching TLS certificate for IP SANs, we can connect CA server org3 for exposing a rest api to query and issue certificates.


### Structure of connect.json
```
{
    "name": "ctb",
    "version": "1.0.0",
    "client": {},
    "channels": {},
    "organizations": {},
    "orderers": {},
    "peers": {},
    "certificateAuthorities": {}
}
```

For this, we need to create connect.json with following information:

- MSP's CA server for org3 address, TLS certificate, username and password. So, that we can register a new client for org3 and use its credentials for connecting to peer of org3. Section `certificateAuthorities` in connect.json
- TLS certificates and address of all peers as while invoking the chaincode request must be sent to majority of peers according to fulfil endorsement policy of chaincode. Section `peers` in connect.json
- Channel information. Section `channels` in connect.json
- organisation org3 information. Section `organisations` in connect.json


### Moving TLS certificate
TLS certificates are required to establish communication with either orderers or peers, so for moving the certificates from `server 1` to `server 2` there is `transfer_assets.sh` script.

```
./transfer_assets.sh tlscert -f <server 1
's ip>  -t <server 2's ip> -l <list of orgs whose certs are moved>
```

For example:
```
./transfer_assets.sh tlscert -f 134.209.145.224  -t 139.59.22.55 -l "org1 org2 browser"
```
This moves org1, org2 and browser TLS certs to `server 2` from `server 1`. Orderer TLS cert is moved by default.
TLS cert for org3 is already present on `server 2` as org3 was created on `server 2`.

### DotEnv file
```
QUERYUSER=          # client credentials CN e.g. tester
USERNAME=           # CA server username for login in this application
PASSWORD=           # CA server password for login in this application
MSP_USERNAME=       # MSP'CA username
MSP_PASSWORD=       # MSP'CA password
CHAINCODE=mycc      # chaincode name
CHANNEL=mychannel   # channel name
CONNECT_JSON=       # relative path of connect.json from server folder
```

### Generating client credentials for CA server
```
node newadmin.js <org name>(e.g. org3)
node newuser.js tester <org name>(e.g. org3)
```

### Starting CA server
```
cd server
npm start
```
alternatively if pm2 is installed:
```
pm2 start pm2.json --only "CA server"
```
This starts the server at `https://<server ip>:8000`

### References
- pm2 docs http://pm2.keymetrics.io/docs/usage/pm2-doc-single-page/
- pm2 Start Multiple Apps With A Single Process File (JSON/JS/YAML) https://futurestud.io/tutorials/pm2-start-multiple-apps-with-a-single-process-file-json-js-yaml
- Information client application for org and connect.json https://hyperledger-fabric.readthedocs.io/en/release-1.4/developapps/developing_applications.html
- sample fabcar client application https://github.com/hyperledger/fabric-samples/tree/release-1.4/fabcar/javascript
- Understanding the Fabcar Network https://hyperledger-fabric.readthedocs.io/en/release-1.4/understand_fabcar_network.html