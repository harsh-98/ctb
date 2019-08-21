## Certificate revocation

### CRLs
When a certificate authority revokes any SSL certificate before their scheduled expiration date and should no longer be trusted.  In order to communicate that revocation, the CA publishes a Certificate Revocation List (CRL). In order to make the CRL accessible, the CRL is published to a repository either an HTTP or LDAP repository. These repositories are then referenced in the CRL Distribution Point (CDP) Extension of a certificate. A client that is checking revocation will first attempt to download a CRL from the CDP location referenced in the CDP extension for checking a certificate revocation. CRL method can lead to huge latencies in the SSL connection and needs a regular updation of CRLs.

### OCSP
OCSP protocol works by using the Hypertext Transfer Protocol (HTTP over TCP) which allows the web browsers and other clients to directly query the issuing certificate authority for the status of an individual SSL certificate in real time and determine if it is valid or not. When a user attempts to access an https site OCSP sends a request for certificate status information then the server sends back a response of "current", "expired," or "unknown." OCSP was intended to replace the CRL problems but it has its own problems which compromised privacy, reliability, and security. With OCSP, web browsers are no longer required to download and cache huge size of CRL files.

### OCSP stapling

With OCSP stapling, rather than requiring the web browser to independently obtain an assurance of a certificate's real time validity, the same web server that provides the certificate along with a “fresh assertion(OCSP response)” of the validity of the security certificate which is a cryptographically signed by the certificate authority's key, it cannot be forged. The web server periodically queries the OCSP responder to receive a refreshed and updated assertion. The TLS protocol was extended to allow a web browser to request and a web server to supply this OCSP information in its initial connection handshake.
OCSP stapling solved most of the OCSP problems like privacy, Bandwidth & OCSP server load, Reliability, Captive portals, and Performance.
OCSP is best solution that we currently have. It is supported by firefox. Chrome has incomplete implementation of OCSP stapling and doesn't block connection when status is revoked.
For integrating ocsp with HFCTB we have used [ocsp](https://github.com/indutny/ocsp) package.

### OCSP STAPLING SETUP
This repository has domain.com certificate which contains ocsp uri under `Authority Information Access` extension. `domain.com` is present at scripts/certs/domain.crt.

### Domain server
ocsp folder contains webserver.js which can run a demo ocsp stapling enabled webserver.
```
node webserver.js ../ctb/scripts/certs/domain.key ../ctb/scripts/certs/domain.crt ../ctb/scripts/certs/ca.crt
```
This start domain server at :4040.

### CA with ocsp records for domain
```
node ocsp.js ../ctb/scripts/certs/without-pass-ca.key ../ctb/scripts/certs/ca/ca.crt
```

Above commands start ocsp enabled CA service at localhost:7000. In the domain.com certificate, this uri is present.

#### Flow communication
Client trying to connect to domain.com, will first get domain.com certificate. Then checks whether it is signed by one of the trusted CAs or not. After that, it gets OCSPURI from certificate and makes OCSPRequest to webserver to get stapling signed by CA. So, webserver first of all checks if it has stapling in cache. If not, then gets a new stapling from CA server at the browser provided URI.

On CA side, whether the certificate is revoked or not is verified and it then signs current timestamp and sends that to webserver. Webserver caches the request and forwards stapling to browser.

Browser verifies that stapling was signed by CA and whether the certificate is valid or not.

Currently, firefox can be used for testing OCSP stapling. And this folder also contains an agent, just made for the purpose of checking OCSP stapling.

After webserver.js and ocsp.js, you can start agent using below command. Also provide the ca certificate:
```
node agent.js ../ctb/scripts/certs/ca.crt
```

### References
- https://www.securitycommunity.tcs.com/infosecsoapbox/articles/2017/04/03/understanding-how-ssl-certificate-revocation-process-works
- https://github.com/indutny/ocsp
- https://pki-tutorial.readthedocs.io/en/latest/expert/component-ca.conf.html # for extfile, major component
- https://tools.ietf.org/html/rfc2560
- https://tools.ietf.org/html/rfc5280
- https://engineering.circle.com/https-authorized-certs-with-node-js-315e548354a2