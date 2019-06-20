var fs = require('fs');
const tls = require('tls');

var https = require('https');

var args = process.argv.slice(2);
var options = {
    key: fs.readFileSync(args[0]),
    cert: fs.readFileSync(args[1]),
    // ca: fs.readFileSync(args[2]),
    rejectUnauthorized: true,
};

// const server = tls.createServer(options, (socket) => {
//     socket.write('welcome!\n');
//     socket.setEncoding('utf8');
//     socket.pipe(socket);
//   });
//   server.listen(8080, () => {
//     console.log('server bound');
//   });

https.createServer(options, function (req, res) {
    console.log(new Date()+' '+
        req.connection.remoteAddress+' '+
        req.method+' '+req.url);
    res.writeHead(200);
    res.end("hello world\n");
}).listen(8080);
console.log("listening")
