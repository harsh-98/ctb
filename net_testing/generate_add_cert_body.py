import os
import json


ca=input("CA:")
domain=input("Domain:")

cafile= "%s/%s.crt" % (ca,ca)
domainfile = "%s/%s.crt" % (domain,domain)

if not os.path.isfile(domainfile):
    domainfile = os.path.join('../scripts/certs/', domainfile)
if not os.path.isfile(cafile):
    cafile = os.path.join('../scripts/certs/', cafile)

with open(cafile,"r") as f:
    CA = "".join(f.readlines())

with open(domainfile,"r") as f:
    DOMAIN = "".join(f.readlines())


SIG=""
if os.path.isfile("%s/%s" % (domain, "sig")):
    with open("%s/%s" % (domain, "sig"),"r") as f:
        SIG = "".join(f.readlines())


a=json.dumps({"certString":DOMAIN,"intermedCert":CA,"sigString": SIG})
print(a)
