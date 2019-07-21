## Cert Generator
`cert_generator.sh` is a automatic script for generating ca, domain certificate, issuing new certificates anad revoking certificates.

##### For generating CA and domain certificates
If you want to generate CA and domain from scratch with number of domain and issue count for each domain, use:

```
./cert_generator.sh -c ca.com -d test.example.com -r -n 2 -i 2
```

__NOTE__: Flags:
- `r` removes all directories.
- `o` with `r` removes all directories except ca and uses existing CA cert for generating domain certificates.
- `n` number of domains
- `i` issue count for each domain


Uses existing CA cert and removes all existing domain certs.
```
./cert_generator.sh -c ca.com -d test.example.com -r -n 2 -i 2 -o
```