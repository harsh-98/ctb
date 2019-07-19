# Add organisation to HLCTB

## Process
We need to define the permissions and anchorPeer of the new organisation. Then fetch the channel's configuration and calculate the changes required in channel's configuration to added new organisation. These changes are stored in `update_in_envelope.pb`. For submitting these changes, we need the permission from majority of peers. This is done by making the current network's peer orgs sign the `update_in_envelope.pb` and then submit it from one of the peers. Now, the channel configuration has updated and new org can join the network. But the current used version of chaincode cannot be instantiated for new org. So, we have to install newer version of chaincode on all peers and upgrade to this new version of chaincode.

## Current architecture
Here,we would be adding new org (org3.example.com) to network. The current architecture of HLCTB networks:
```
Orderer:
- orderer.example.com

Peers: (each org has one CA, one peer with couchDB)
- org1.example.com
- org2.example.com
- browser.example.com
```

## Steps


We need to generate the crypto material and docker-compose specific to the org we want to deploy.
```
./eyfn.sh generate -n 3 <<< "Y"
```

Below command brings the container up and also generate the difference between the current config of channel vs modified config of channel. This `diff` is stored in `update_in_envelope.pb`.
```
./eyfn.sh up -n 3 <<< "Y"
```

Then `update_in_envelope.pb` needs to be signed by majority of the orgs present in channel. Information relating how many signatures are needed is present under channel section in configtx.yaml.

```
Channel:
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
```

The signed `update_in_envelope.pb` has to be submitted to the network.
```
./ctb.sh submit
```

Now, for instantiating the chaincode on the peers of new organisation, an upgrade request is sent to network for changing the used chaincode version.
For this install the new chaincode version on all the peers in the network.
```
./ctb.sh install -n 3 -v 2.0
cd new_org
./eyfn.sh join  -n 3 -v 2.0
./eyfn.sh install -n 3 -v 2.0
```

Then upgrade the instantiated chaincode to newer version.
```
./ctb.sh upgrade  -n 3 -v 2.0
```


## Final architecture
Server 1:
```
Orderer:
- orderer.example.com

Peers: (each org has one CA, one peer with couchDB)
- org1.example.com
- org2.example.com
- browser.example.com
```

Server 2:
```
Peers: (each org has one CA, one peer with couchDB)
- org3.example.com
```

## Reference
- [Code of fabric-sample for fabric 1.4](https://github.com/hyperledger/fabric-samples/tree/release-1.4/)

After reading this, you can go through [adding IP SANs to orderers' and peers' certs](add_ip_sans.md)
