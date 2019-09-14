# Revoking a new certificate with the consent of the CA.
# Here, the third argument is signature of domain_new.crt signed by private key of CA.

node newinvoke.js tester ../scripts/certs/localhost2/localhost.crt ../scripts/certs/ca/ca.crt ../scripts/certs/localhost2/sig_by_CA  revoke
