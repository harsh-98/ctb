'use strict';

const tls = require('tls');
const fs = require('fs');
const port = 8000;

var args = process.argv.slice(2);

const options = {
    key: fs.readFileSync(args[0]),
    cert: fs.readFileSync(args[1]),
    ca: fs.readFileSync(args[2])
};

var server = tls.createServer(options, (socket) => {
    socket.write(options.cert);
    socket.setEncoding('utf8');
    socket.pipe(socket);
})

    .on('connection', function (c) {
        console.log('insecure connection');
    })

    .on('secureConnection', function (c) {
        // c.authorized will be true if the client cert presented validates with our CA
        console.log('secure connection');
    })

    .listen(port, function () {
        console.log('server listening on port ' + port + '\n');
    });