# Add organisation to HLCTB

We need to generate the crypto material and docker-compose specific to the org we want to deploy.
```
./ctb.sh generate <<< "Y"
```

Below command brings the container up and also generate the difference between the config of channel vs modified config of channel. This `diff` is stored in `update_in_envelope.pb`.
```
./ctb.sh up  <<< "Y"
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

