# Deploying HLCTB to Cloud

We are using digitalocean droplet from hosting the HLCTB. Specifications of system are given below:

```
OS: Ubuntu 18.04.2 LTS
RAM: 4GB
CPU: Intel(R) Xeon(R) CPU E5-2650 v4 @ 2.20GHz
```


## Setup

__NOTE__: Using tmux is recommended because we need multiple terminals for running many processes and also for configuring different services. And I am assuming that all repos are cloned in home directory.

__REQUIRED SOFTWARE__: `make g++ node babel-node pm2`
For installing node.js, refer [gist](https://gist.github.com/d2s/372b5943bce17b964a79)
```
sudo apt-get install g++ make
npm install -g babel-cli pm2 nodemon
```

### Installing docker and adding user to docker group
```
sudo apt-get install docker docker-compose # installing docker
sudo systemctl restart docker.service # for starting the docker service
sudo usermod -a -G docker ctb # adding user to docker group so that he can exec commands
exec su -- ctb # this is required as adding to group is not reflected immediately so this will login the user in a session hences refresh the groups for user
```

### Starting the HLCTB
```
git clone git@github.com:harsh-98/ctb.git # cloning this repo
cd ctb
./ctb.sh down <<< "Y" &&  ./ctb.sh generate <<< "Y" && ./ctb.sh up  <<< "Y"  && ./ctb.sh test <<< "Y" # this will bootstrap all the steps for creating the crypto material, starting the nodes and deploying chaincode
```

### Create docker images for server and client of blockchain-explorer
```
cd ~/ctb/blockchain-explorer
docker build  -t hlf-explorer-server:1.0 - < server-Dockerfile
docker build  -t hlf-explorer-client:1.0 - < client-Dockerfile
```

### Installing and configuring postgres db for blockchain-explorer
Refer [this](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-18-04) digitalocean guide.
Other References: [blockchain-explorer](https://github.com/hyperledger/blockchain-explorer)

```
cd /etc/postgresql/<version>/main

sudo vim postgresql.conf # change the listen_addresses to whichever interface you want to listen on. In this case, '*' which means all interfaces.

sudo vim pg_hba.conf # allow accepting connections from outside the network so that blockchain-explorer running in docker can connect. In this case, add `host    all             all             <docker-host-ip-addr>/24            md5`

cd ~ # return to home
git clone git@github.com:hyperledger/blockchain-explorer.git # clone the blockchain-explorer
cd ~/blockchain-explorer/app/persistence/fabric/postgreSQL/db

# for running below command node and jq are required
./createdb.sh # this will add the tables structure for blockchain-explorer db and add a user
```

### Generating credentials for connecting blockchain-explorer to HLCTB
```
# make sure make and g++ are installed
cd ~/ctb/server
rm -rf wallet && node newadmin.js org1 # for generating user credentials for org1
cd ~/ctb/blockchain-explorer
docker-compose -f docker-compose-hlfexplorer.yaml up & # this will start the server/client of blockchain-explorer
```

### Starting a CA
For querying, adding and revoking certificates we need a running CA.
```
cd ~/ctb/server
npm install
npm start # start the CA server
```

## After Setup
After going through the setup procedure, we have following running and accessible outside of localhost.

- A couchDb connected to one of the peers. `<ip-addr>:5984`
- The explorer interface for monitoring the network. `<ip-addr>:3000`
- The CA server for adding, revoking and querying the certificates. `<ip-addr>:8000`

## Start pm2 service
This starts report server for viewing caliper generated reports at `:4000`, CA server at `:8000` and channel config api at `:5000`.
```
pm2 start pm2.json
```

__NOTE__: If you followed [Starting a CA](#starting-a-ca) section, you will get error for `pm2 start pm2.json at 4000 port` with error code `EADDRINUSE`.
