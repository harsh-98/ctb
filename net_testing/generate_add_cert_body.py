ca="sub.example.com"
domain=input("Domain:")

cafile= "%s/%s.crt" % (ca,ca)
domainfile = "%s/%s.crt" % (domain,domain)
with open(cafile,"r") as f:
    CA = "".join(f.readlines())

with open(domainfile,"r") as f:
    DOMAIN = "".join(f.readlines())

with open("%s/%s" % (domain, "sig"),"r") as f:
    SIG = "".join(f.readlines())

import json

a=json.dumps({"certString":DOMAIN,"intermedCert":CA,"sigString": SIG})
print(a)
