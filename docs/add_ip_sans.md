## Error 1
After joining a new org (org3) to network, peer of org3 were not able to connect to orderer. As the channel config in configtx.yaml have the orderer address as orderer.example.com:7050, which would work when the whole network is within one docker environment. But in this case, org3 is running on a different server. Hence, cannot resolve orderer.example.com. Error:
>Error: failed to connect to orderer.example.com:7050 failed to create new connection context deadline exceeded.

## Error 2
So, I changed the addr in configtx to `server 1` ip addr and exposed orderer service at 7050. But even that was failing as tlscert for orderer had orderer.example.com as subjectName and IP of the `server 1`. And it was failing with below error.


>peer0.org3.example.com | 2018-04-25 07:22:21.107 UTC [gossip/discovery] func1 -> WARN 1df Could not connect to {`server1-ip:7050` [] [] `server1-ip:7050` <nil>} : x509: cannot validate certificate for server1-ip because it doesn't contain any IP SANs.

## Solution

So, I have to generate new TLS certificates for orderer.example.com, and also for the peers of org1.example.com, org2.example.com, org3.example.com and browser.example.com which includes the corresponding server ip. While generating new certificate I have to match the cert extension such as basicConstraints, keyUsage etc. For this, there is `patchOrdererAndOrgs` function in scripts/common-utils.sh, which patches TLScerts for all orderers and peers present in crypto-config folder.

__NOTE__: One important point to remember is private/public key pair used by fabric for generating certs is ECDSA not RSA. Though for generating the certs the processing is same for ECDSA and RSA key pair.


## References
- Solution for adding IP SANs to certificates https://serverfault.com/questions/611120/failed-tls-handshake-does-not-contain-any-ip-sans
- Working with ECDSA and RSA key pair and generating certs: https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art054.
- For generating ECDSA key pair and self-signed certs refer first answer https://superuser.com/questions/644297/parameters-to-create-a-self-signed-dsa-certificate-on-ubuntu-12-04
- Information on different possible values for available extensions(i.e. keyUsage, extendedKeyUsage) for certs: https://www.ibm.com/support/knowledgecenter/sl/SSKTMJ_9.0.1/admin/conf_keyusageextensionsandextendedkeyusage_r.html
- All possible values for different fields in extfile openssl x509 https://www.ibm.com/support/knowledgecenter/en/SSB23S_1.1.0.13/gtps7/cfgcert.html
- Question on [page](https://security.stackexchange.com/questions/49229/root-certificate-key-usage-non-self-signed-end-entity) has exact syntax of possible values for extensions.
- For adding subjectKeyIdentifier to certificate refer first answer on https://stackoverflow.com/questions/21179132/create-self-signed-certificate-with-subject-key-identifier
- For including `X509v3 extensions` in certificate refer first answer https://security.stackexchange.com/questions/150078/missing-x509-extensions-with-an-openssl-generated-certificate
- CryptoGen Binary for Fabric 1.4 https://hyperledger-fabric.readthedocs.io/en/release-1.4/commands/cryptogen.html

After reading this, you can go through [adding CA server](new_org_CA_server.md)

