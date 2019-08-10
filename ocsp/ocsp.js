var fs = require('fs');
var ocsp = require('ocsp');
const tls = require('tls');

var https = require('https');

var args = process.argv.slice(2);
var options = {
    key: fs.readFileSync(args[0]),
    cert: fs.readFileSync(args[1]),
    // ca: fs.readFileSync(args[2]),
};

var server = ocsp.Server.create(options);

server.addCert("13ee62ce1c5734fde83ecab5aa35fd64a32fa5ab", 'good');
// server.addCert("13ee62ce1c5734fde83ecab5aa35fd64a32fa5ab", 'revoked', {
//   revocationTime: new Date(),
//   revocationReason: 'keyCompromise'
// });
server.listen(7000);
