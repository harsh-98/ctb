#create channel
export CHANNEL_NAME=mychannel
peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

#########
# join channel
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
DELAY=2
peer channel join -b mychannel.block

sleep $DELAY

peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/cert/

sleep $DELAY

peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n mycc  -v 1.0 -c '{"Args":[]}' -P "AND ('Org1MSP.peer')"
exit 1
sleep $DELAY

DOMAIN=$(cat scripts/certs/domain.crt)
CA=$(cat scripts/certs/ca.crt)

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt -c '{"Args":["addCertificate","-----BEGIN CERTIFICATE-----\nMIID/zCCAuegAwIBAgIUdH0HZRrEUIaxNQVDoYBcK6R6YVcwDQYJKoZIhvcNAQEL\nBQAwgY8xCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMQwwCgYDVQQH\nDANjaXQxITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEMMAoGA1UE\nCwwDY2l0MRQwEgYDVQQDDAtleGFtcGxlLmNvbTEWMBQGCSqGSIb3DQEJARYHYUBh\nLmNvbTAeFw0xOTA2MDExOTM1NThaFw0yMDA1MzExOTM1NThaMIGOMQswCQYDVQQG\nEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEMMAoGA1UEBwwDY2l0MSEwHwYDVQQK\nDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxDDAKBgNVBAsMA2NpdDETMBEGA1UE\nAwwKZG9tYWluLmNvbTEWMBQGCSqGSIb3DQEJARYHYUBhLmNvbTCCASIwDQYJKoZI\nhvcNAQEBBQADggEPADCCAQoCggEBAKUFCX2KAzkPQuZgfPokjC8BKsXYrYUk91WM\nAeDOP/U3EzEIWnobVapnZ7oXtTKPHZ/vb72BCiSR37A92HzcA5TLH12NGXR89yeU\n6E3NcytChs8o1WuMSctvGRpwA3SUrzjPbC4CsL6tkdfSAjpQeAgtnBMZ8s4K3Sbd\naTDIrvv+O44bMvzVa/5qVoHDenlDH3hz0Wuks8uavs5NbWotIzAnHjg27tMQu9Yj\nv+wSYIu8UmamYLdyzA71MTy+Yxk7/+fYxSIlWofPMgmeEHhjEKfSUFoA2IPWOZai\nk5pKiQqVmumOiNhxFms9BzdH2N6YxS2RwQ3+JxicEw+HbKlzOIUCAwEAAaNSMFAw\nHwYDVR0jBBgwFoAUSSgXnRZ8Q4rbXKPAJQMY12I0PDUwCQYDVR0TBAIwADALBgNV\nHQ8EBAMCBPAwFQYDVR0RBA4wDIIKZG9tYWluLmNvbTANBgkqhkiG9w0BAQsFAAOC\nAQEAynMJcfIugfXxrXBBBxV9RXP/m0BCiujSS4kYU/rCNjBx4twpRIybMeEKq1Nq\nzDypHUKevd1dUfMkPiQ8V5tyNTSKT+ymmz4NxMnrpPwZo8kn797eqzcB+CRdBWZy\n1nJPM8DjK8QlOgfOqrHub4joyIhylJ5B+szUOMQO3SabC5kQ1Zbmqfu8cjxopiQz\nq93lywrbNlxyOkMtm5/A7auB1lve/RNRf+ZgwCd0iDeiNEc0C6K0louGo2jtTGk2\nP67Ra+rDaXuW0Mase36pMWJ8yMVxwLlQ32jO+BwcwrUJAjcc4yFMGLgNF+s0d4yq\nJJxKLe/a7ZoM2kqMbBHkyGIxtg==\n-----END CERTIFICATE-----\n","-----BEGIN CERTIFICATE-----\nMIIEATCCAumgAwIBAgIUeUNTMXVFd+qOEEaVtgVIETGixLEwDQYJKoZIhvcNAQEL\nBQAwgY8xCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMQwwCgYDVQQH\nDANjaXQxITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEMMAoGA1UE\nCwwDY2l0MRQwEgYDVQQDDAtleGFtcGxlLmNvbTEWMBQGCSqGSIb3DQEJARYHYUBh\nLmNvbTAeFw0xOTA2MDExOTIzMzlaFw0yMDA1MzExOTIzMzlaMIGPMQswCQYDVQQG\nEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEMMAoGA1UEBwwDY2l0MSEwHwYDVQQK\nDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxDDAKBgNVBAsMA2NpdDEUMBIGA1UE\nAwwLZXhhbXBsZS5jb20xFjAUBgkqhkiG9w0BCQEWB2FAYS5jb20wggEiMA0GCSqG\nSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDYjI2vuoZYn269di+8I/5dTFMQM6pcyeSn\n8oSzYTPUVmyjI4sAbNU/n8hJ9h7g/cGlF+cPvBBvxwoh62yYZLoCLm0qBFA0gGWX\nPGOVDg90D1dJDvUp4/MMWU/pB5jipdsKFPbAXsSkQIp7QUZEMFOR8gGbZ5HMtFBt\nlUoWCrttlu1+4r6gs8WWqB52eEo1etWyvBlptauz75qbJvZR91+ARyM9KoPC9kox\nkwqXRJ/sjSqLxH4oXOfKA//bCuiiwSqZgHE5QFlAS3cFyNmRaN8XItPWsIUSkqSZ\nzOptEh8mIcy6vf0zMLwr6aPkOFbx1FCKKSEycGeizJOJDURwhg3fAgMBAAGjUzBR\nMB0GA1UdDgQWBBRJKBedFnxDittco8AlAxjXYjQ8NTAfBgNVHSMEGDAWgBRJKBed\nFnxDittco8AlAxjXYjQ8NTAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUA\nA4IBAQBqbD5oiOK2Zqw2i7b0bs5voGvYkRGZCZKiOjU4tSBjc5efi7l01SM+Fzp7\n4w8VrY3dHCEETqzl8j5L4dlHv6zRZrg96SHEweHyIjhFa+MQEBAmce5ZaEjVoWxy\nSGbTyZzQjD6G/HYa/Q1FM9YJcvqyYCgVcz/fgcviRuW2y6Wb40lA7KEJaLB9Xv8u\njPjizwFZm6XpEKhhb7kB+l/7Nxt2k2H8q2DyBWMYR9OOYhw+2NWonVq8vZeCzP6W\nucOWLd+PtSouc3U5hd9yU/jGMArG202btTKOSsnRd9Wm7x5DdJuOusK6snlAZlYj\ns40Hp/UKmU/mAR9MRUnMj1v8gkML\n-----END CERTIFICATE-----\n",""]}'

#domain.com
#-----BEGIN CERTIFICATE-----\nMIID/zCCAuegAwIBAgIUdH0HZRrEUIaxNQVDoYBcK6R6YVcwDQYJKoZIhvcNAQEL\nBQAwgY8xCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMQwwCgYDVQQH\nDANjaXQxITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEMMAoGA1UE\nCwwDY2l0MRQwEgYDVQQDDAtleGFtcGxlLmNvbTEWMBQGCSqGSIb3DQEJARYHYUBh\nLmNvbTAeFw0xOTA2MDExOTM1NThaFw0yMDA1MzExOTM1NThaMIGOMQswCQYDVQQG\nEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEMMAoGA1UEBwwDY2l0MSEwHwYDVQQK\nDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxDDAKBgNVBAsMA2NpdDETMBEGA1UE\nAwwKZG9tYWluLmNvbTEWMBQGCSqGSIb3DQEJARYHYUBhLmNvbTCCASIwDQYJKoZI\nhvcNAQEBBQADggEPADCCAQoCggEBAKUFCX2KAzkPQuZgfPokjC8BKsXYrYUk91WM\nAeDOP/U3EzEIWnobVapnZ7oXtTKPHZ/vb72BCiSR37A92HzcA5TLH12NGXR89yeU\n6E3NcytChs8o1WuMSctvGRpwA3SUrzjPbC4CsL6tkdfSAjpQeAgtnBMZ8s4K3Sbd\naTDIrvv+O44bMvzVa/5qVoHDenlDH3hz0Wuks8uavs5NbWotIzAnHjg27tMQu9Yj\nv+wSYIu8UmamYLdyzA71MTy+Yxk7/+fYxSIlWofPMgmeEHhjEKfSUFoA2IPWOZai\nk5pKiQqVmumOiNhxFms9BzdH2N6YxS2RwQ3+JxicEw+HbKlzOIUCAwEAAaNSMFAw\nHwYDVR0jBBgwFoAUSSgXnRZ8Q4rbXKPAJQMY12I0PDUwCQYDVR0TBAIwADALBgNV\nHQ8EBAMCBPAwFQYDVR0RBA4wDIIKZG9tYWluLmNvbTANBgkqhkiG9w0BAQsFAAOC\nAQEAynMJcfIugfXxrXBBBxV9RXP/m0BCiujSS4kYU/rCNjBx4twpRIybMeEKq1Nq\nzDypHUKevd1dUfMkPiQ8V5tyNTSKT+ymmz4NxMnrpPwZo8kn797eqzcB+CRdBWZy\n1nJPM8DjK8QlOgfOqrHub4joyIhylJ5B+szUOMQO3SabC5kQ1Zbmqfu8cjxopiQz\nq93lywrbNlxyOkMtm5/A7auB1lve/RNRf+ZgwCd0iDeiNEc0C6K0louGo2jtTGk2\nP67Ra+rDaXuW0Mase36pMWJ8yMVxwLlQ32jO+BwcwrUJAjcc4yFMGLgNF+s0d4yq\nJJxKLe/a7ZoM2kqMbBHkyGIxtg==\n-----END CERTIFICATE-----\n

#d2.com
#-----BEGIN CERTIFICATE-----\nMIID9zCCAt+gAwIBAgIUdH0HZRrEUIaxNQVDoYBcK6R6YVgwDQYJKoZIhvcNAQEL\nBQAwgY8xCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMQwwCgYDVQQH\nDANjaXQxITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEMMAoGA1UE\nCwwDY2l0MRQwEgYDVQQDDAtleGFtcGxlLmNvbTEWMBQGCSqGSIb3DQEJARYHYUBh\nLmNvbTAeFw0xOTA2MDEyMzI0MzlaFw0yMDA1MzEyMzI0MzlaMIGKMQswCQYDVQQG\nEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEMMAoGA1UEBwwDY2l0MSEwHwYDVQQK\nDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxDDAKBgNVBAsMA2NpdDEPMA0GA1UE\nAwwGZDIuY29tMRYwFAYJKoZIhvcNAQkBFgdhQGEuY29tMIIBIjANBgkqhkiG9w0B\nAQEFAAOCAQ8AMIIBCgKCAQEAwdFzdpBU5YQV1i80VxhDyEqxdjE0Eq8PzT1Fb3CD\nViud0CYhRphH3baCizRgTt92V3u8v4Oj1mW4XNbIiBXf0U4MgRnUY5URQaCIp6zO\n6oZoVRksSqx2KgkHBkju4TOusiTHPk+2c0RSkx3OziebJbWWxYmJYODmmL7H7GJ5\nnKj+ykeVzh03T9P2rJDZVFG4zlXZnElR4TApdKXmSnT0dkc2FLLfpdwc5yJuh7t3\n0D1+ymYtAIL6E8+xkATpRAmx5GzBaByC0nFR7PO4/thi1PBfX3AINOS9pAF0J+om\nkE6e1C7E9dckBYP8CxL6y8qGHkjESurshOAuV8mcBRRegwIDAQABo04wTDAfBgNV\nHSMEGDAWgBRJKBedFnxDittco8AlAxjXYjQ8NTAJBgNVHRMEAjAAMAsGA1UdDwQE\nAwIE8DARBgNVHREECjAIggZkMi5jb20wDQYJKoZIhvcNAQELBQADggEBAK7n0hju\n8uRw3M7ErxB6IPe7Rq47l6tRrNf5y5lgycvxzUJ0BWbMtTXxBT/EfyYqlEatpOna\nP6u6n48h4iI6mqneXXLIj/Eg95G/3/KDbe8C+cI7mNKKngzTH42LtlZe6ObFgRWQ\noGUmZ1DThiJfAwkDSzFh8e0KMOBpk+VD+1VeuYPKITcIfS536i22lStum2EHvT65\n7KrOo4AC0hxILfKIpZ/pjPmWxTfJi3hRvs/ayqxGWlKvilg/vKXBZhtfVbpEYqOu\nEVR8z0v+7JVfbAGT+Y8diEbkrGiuN8JewbqK4xOPVJcpgnMFLa4GBDDNHr+E4KKJ\nVh2Y/TPBRMKQ5Mc=\n-----END CERTIFICATE-----\n

sleep $DELAY

peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["queryCertificate","domain.com"]}'
sleep $DELAY

exit 1
CORE_PEER_ADDRESS=peer1.org1.example.com:8051
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
peer channel join -b mychannel.block

CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_ADDRESS=peer0.org2.example.com:9051
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
peer channel join -b mychannel.block

CORE_PEER_ADDRESS=peer1.org1.example.com:10051
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org2.example.com/tls/ca.crt
peer channel join -b mychannel.block

CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/browser.example.com/users/Admin@browser.example.com/msp
CORE_PEER_LOCALMSPID="BrowserMSP"
CORE_PEER_ADDRESS=peer0.browser.example.com:9061
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/browser.example.com/peers/peer0.browser.example.com/tls/ca.crt
peer channel join -b mychannel.block

CORE_PEER_ADDRESS=peer1.org1.example.com:10061
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.browser.example.com/tls/ca.crt
peer channel join -b mychannel.block

#######
# update anchor peer
peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/BrowserMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

#######

# peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"