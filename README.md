#CTB Using Hyperledger
This is based on paper [Certificate Transparency Using Blockchain](https://eprint.iacr.org/2018/1232).

## Generate crypto-config and transactions
```
./ctb.sh generate
```

## Starting network and testing
```
./ctb.sh up
```

Note: Single command `./ctb.sh generate <<< "Y" && ./ctb.sh up  <<< "Y"`

## Structure
Certificates are available in `scripts/certs`. There are:
- `domain.*`: domain related crypto material
- `ca.*`: CA related crypto material
- `d2.*`: new crypto material for same domain signed by current cert

chaincode/main.go contains chaincode CTB described in above paper.

I have modified [byfn](https://hyperledger-fabric.readthedocs.io/en/release-1.4/build_network.html) scripts and config files to incorporate CTB architecture.