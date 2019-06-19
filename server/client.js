#!/usr/bin/env node
'use strict';


var Fabric_Client = require('fabric-client');
var path = require('path');
var util = require('util');
var os = require('os');

var fabric_client = new Fabric_Client();

var channel = fabric_client.newChannel('mychannel');
var peer = fabric_client.newPeer('grpc://localhost:10051');
channel.addPeer(peer);

var member_user = null;
var store_path = path.join(__dirname, 'hfc-key-store');
var tx_id = null;
var user = 'userChrome';

var args = process.argv.slice(2);

const port = 8000;
const hostname = args[0];

const tls = require('tls');
var fs = require('fs');

var cert_from_server = null;

const options = {
    host: hostname,
    port: port,
    ca: fs.readFileSync(args[1])
};

var socket = tls.connect(options, () => {
    console.log('client connected - ',
        socket.authorized ? 'authorized' : 'unauthorized');
    if (socket.authorized) {


        Fabric_Client.newDefaultKeyValueStore({

            path: store_path

        }).then((state_store) => {

            fabric_client.setStateStore(state_store);
            var crypto_suite = Fabric_Client.newCryptoSuite();
            var crypto_store = Fabric_Client.newCryptoKeyStore({path: store_path});
            crypto_suite.setCryptoKeyStore(crypto_store);
            fabric_client.setCryptoSuite(crypto_suite);

            return fabric_client.getUserContext(user, true);

        }).then((user_from_store) => {

            if (user_from_store && user_from_store.isEnrolled()) {
                console.log('Successfully loaded ' + user + ' from persistence');
                member_user = user_from_store;
            } else {
                throw new Error('Failed to get ' + user + '.... run registerUser.js');
            }

            // queryCertificate chaincode function - requires 1 argument, subjectName
            const request = {
                //targets : --- letting this default to the peers assigned to the channel
                chaincodeId: 'ca-blockchain',
                fcn: 'queryCertificate',
                args: [hostname]
            };

            // send the query proposal to the peer
            return channel.queryByChaincode(request);
        }).then((query_responses) => {
            console.log("Query has completed, checking results");
            // query_responses could have more than one  results if there multiple peers were used as targets
            if (query_responses && query_responses.length === 1) {
                if (query_responses[0] instanceof Error) {
                    console.error("error from query = ", query_responses[0]);
                    socket.end();
                } else {
                    console.log("Response is ", query_responses[0].toString());
                    var responseJSON = JSON.parse(query_responses[0].toString());
                    if (responseJSON.certString === cert_from_server) {
                        console.log("Certificate is present and matched!");
                    } else {
                        console.log('Certificate mismatch!!!!');
                        socket.end();
                    }
                }
            } else {
                console.log("No payloads were returned from query");
                socket.end();
            }
        }).catch((err) => {
            console.error('Failed to query successfully :: ' + err);
            socket.end();
        });


    }

    process.stdin.pipe(socket);
    process.stdin.resume();

    // socket.end();
})

    .setEncoding('utf8')

    .on('data', (data) => {
        cert_from_server = data;
        console.log('Received certificate from server!');
    })

    .on('end', () => {
        console.log("End connection");
    });