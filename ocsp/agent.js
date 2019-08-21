var ocsp = require('ocsp');
var https = require('https');
var fs = require('fs');


var args = process.argv.slice(2);
var ca = fs.readFileSync(args[0]);
var a = new ocsp.Agent();

var req = https.get({
  host: 'domain.com',
  port: 4040,
  agent: a,
  ca: ca
}, function (res) {
  res.resume();
});