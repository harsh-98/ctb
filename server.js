var fs = require('fs');
var https = require('https');

var args = process.argv.slice(2);
var options = {
    key: fs.readFileSync(args[0]),
    cert: fs.readFileSync(args[1]),
    ca: fs.readFileSync(args[2]),
};

https.createServer(options, function (req, res) {
    console.log(new Date()+' '+
        req.connection.remoteAddress+' '+
        req.method+' '+req.url);
    res.writeHead(200);
    res.end("hello world\n");
}).listen(8080);
console.log("listening")
