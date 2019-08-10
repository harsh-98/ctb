var fs = require('fs');
var ocsp = require('ocsp');
const tls = require('tls');

var https = require('https');

var args = process.argv.slice(2);
var options = {
    key: fs.readFileSync(args[0]),
    cert: fs.readFileSync(args[1]),
    ca: fs.readFileSync(args[2]),
};

var cache = new ocsp.Cache();




var server = https.createServer(options, function(req, res) {
    console.log(new Date()+' '+
    req.connection.remoteAddress+' '+
    req.method+' '+req.url);
    res.writeHead(200);
    res.end('hello world');
});

server.on('OCSPRequest', function(cert, issuer, cb) {
    console.log("OCSPRequest")
    ocsp.getOCSPURI(cert, function(err, uri) {
    if (err) return cb(err);
    if (uri === null) return cb();

    var req = ocsp.request.generate(cert, issuer);
    console.log("req")
    cache.probe(req.id, function(err, cached) {
        if (err) return cb(err);
        console.log("sample")
        console.log(cached.response)
        if (cached !== false) return cb(null, cached.response);

        var options = {
            url: uri,
            ocsp: req.data
        };

      cache.request(req.id, options, cb);
    });
  });
});

server.listen(4000);