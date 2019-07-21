# Crypto-config Demystified

This article explains how different keys and certs under crypto-config are related, even more so why these files are generated in first place.

__NOTE__: ALl the key pair under crypto-config are ECDSA and certificates are x509 with pem encoding.

### OrdererOrganisation structure

Below I have refered the cert(number) by (ref-number)
```
├── ordererOrganizations
│   └── example.com                         # Orderer's domain
│       ├── ca (1)                          # It contains ca.example.com self-signed certificate and corresponding private key
│       ├── msp                             # contains the cert for ca, tlsca and admins
│       │   ├── admincerts                 # Contains (3)
│       │   ├── cacerts                    # Contains (1)
│       │   └── tlscacerts                 # Contains (2)
│       ├── orderers
│       │   ├── orderer.example.com
│       │   │   ├── msp
│       │   │   │   ├── admincerts       # Contains (3)
│       │   │   │   ├── cacerts          # Contains (1)
│       │   │   │   ├── keystore         # Contains private key for orderer.example.com (4) signed by (1)
│       │   │   │   ├── signcerts (4)    # Contains certificate for orderer.example.com signed by (1). It is used for Digital Signature
│       │   │   │   └── tlscacerts       # Contains (2)
│       │   │   └── tls                   # Contains (2) as ca.crt, private key as server.key and crt for  orderer.example.com signed by (2) as server.crt
│       ├── tlsca (2)                       # It contains tlsca.example.com self-signed certificate and corresponding private key. This cert is used for signing tls cert of all users and sub-domains orderer of example.com
│       └── users
│           └── Admin@example.com
│               ├── msp
│               │   ├── admincerts         # Contains (3)
│               │   ├── cacerts            # Contains (1)
│               │   ├── keystore           # Contains private key for Admin@example.com (3) signed by (1)
│               │   ├── signcerts (3)      # Contains certificate for Admin@example.com signed by (1). It is used for Digital Signature
│               │   └── tlscacerts         # Contains (2)
│               └── tls                     # Contains (2) as ca.crt, private key as client.key and crt for  Admin@example.com signed by (2) as client.crt
```

### PeerOrganisation strucuture

The structure is similar to [OrdererOrganisation structure].(#ordererorganisation-structure) Below I have refered the cert(number) by (ref-number)

```
├── peerOrganizations
│   └── org1.example.com                    # Peer's domain
│       ├── ca (1)                          # It contains ca.org1.example.com self-signed certificate and corresponding private key
│       ├── msp                             # contains the cert for ca, tlsca and admins
│       │   ├── admincerts                 # Contains (3)
│       │   ├── cacerts                    # Contains (1)
│       │   └── tlscacerts                 # Contains (2)
│       ├── peers
│       │   ├── peer0.org1.example.com
│       │   │   ├── msp
│       │   │   │   ├── admincerts       # Contains (3)
│       │   │   │   ├── cacerts          # Contains (1)
│       │   │   │   ├── keystore         # Contains private key for peer0.org1.example.com (4) signed by (1)
│       │   │   │   ├── signcerts (4)    # Contains certificate for peer0.org1.example.com signed by (1). It is used for Digital Signature
│       │   │   │   └── tlscacerts       # Contains (2)
│       │   │   └── tls                   # Contains (2) as ca.crt, private key as server.key and crt for  peer0.org1.example.com signed by (2) as server.crt
│       ├── tlsca (2)                       # It contains tlsca.example.com self-signed certificate and corresponding private key. This cert is used for signing tls cert of all users and peers of org1.example.com
│       └── users
│           └── Admin@org1.example.com
│               ├── msp
│               │   ├── admincerts         # Contains (3)
│               │   ├── cacerts            # Contains (1)
│               │   ├── keystore           # Contains private key for Admin@org1.example.com (3) signed by (1)
│               │   ├── signcerts (3)      # Contains certificate for Admin@org1.example.com signed by (1). It is used for Digital Signature
│               │   └── tlscacerts         # Contains (2)
│               └── tls                     # Contains (2) as ca.crt, private key as client.key and crt for  Admin@org1.example.com signed by (2) as client.crt
```


### Tool to investigate crypto-config
Probably best tool to investigate crypto-config is `openssl`
```
openssl x509 -in <certificate-path> -text -noout
```