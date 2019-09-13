const tls = require('tls');
const fs = require('fs');
const axios = require('axios');


var args = process.argv.slice(2);
const options = {
  ca: [ fs.readFileSync(args[0]) ]
};

function getPEMCert(derBuffer){
    var prefix = '-----BEGIN CERTIFICATE-----\n';
    var postfix = '-----END CERTIFICATE-----';
    var pemText = prefix + derBuffer.toString('base64').match(/.{0,64}/g).join('\n') + postfix;
    return pemText;
}


let domain = 'localhost';

var socket = tls.connect(8080, domain, options, async () => {
  console.log('SSL PKI authenication status: ',
  socket.authorized ? 'Success' : 'Failed');
    let derBuffer = socket.getPeerCertificate().raw;
    let siteCert = getPEMCert(derBuffer);

    const resp  = await axios.get(`http://localhost:8000/query/queryCertificate?subjectName=${domain}`)
    let json = resp.data;

    // console.log(siteCert);
    // console.log(json['certString']);
    if(json['certString'].trim() == siteCert){
      if (json['revokeStatus'] == "notRevoked"){
        console.log("Valid certificate: present on ctb network");
      }else {
        console.log("certificate has been revoked");
      }

    }else {
      console.log("invalid");
    }


});
