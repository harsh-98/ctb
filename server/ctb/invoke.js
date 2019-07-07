/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');
require('dotenv').config()

const ccpPath = path.resolve(__dirname, 'connect.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

async function main(req, res, next) {
    if (!req.isAuthenticated()){
        res.status(403).json({"response": "Not authenticated."});
    }

    var args = process.argv.slice(2);
    let username = process.env.QUERYUSER;
    let CHAINCODE = process.env.CHAINCODE;
    let CHANNEL = process.env.CHANNEL;

    let fcn = req.params.fcn;
    let certString = req.body['certString'];
    let intermediateCertString = req.body['intermedCert'];
    var sigString = req.body['sigString'] ? req.body['sigString'] : ""

    let tx_id = "mycc";
    if (fcn == "addCertificate") {
            var request = {
        //targets: let default to the peer assigned to the client
            chaincodeId: CHAINCODE,
            fcn: 'addCertificate',
            args: [certString, intermediateCertString, sigString],
            chainId: CHANNEL,
        };
    } else if (fcn == "revokeCertificate") {
          var request = {
        //targets: let default to the peer assigned to the client
            chaincodeId: tx_id,
            fcn: 'revokeCertificate',
            args: [certString, intermediateCertString, sigString],
            chainId: CHANNEL,
        }
    } else {
        res.status(400).json({"response": "Bad function name"});
    }

    try {
        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);
        console.log(`${request}`);

        // Check to see if we've already enrolled the user.
        const userExists = await wallet.exists(username);
        if (!userExists) {
            console.log('An identity for the user username does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: username, discovery: { enabled: false } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork(request.chainId);

        // Get the contract from the network.
        const contract = network.getContract(request.chaincodeId);

        // Submit the specified transaction.
        // addCertificate transaction - requires 2 args, ex: ('addCertificate', '')
        // addCertificate transaction - requires 3 args, ex: ('addCertificate', '')
        // revokeCertificate transaction - requires 3 args , ex: ('revokeCertificate', '')
        try {
            await contract.submitTransaction(request.fcn, ...request.args);
        } catch (error) {
            // throw new Error(req.body['peer']);
            res.status(500).json({"response": "Transaction failed"});
        }
        // Disconnect from the gateway.
        await gateway.disconnect();
        res.status(200).json({"response": "Transaction has been submitted"});

    } catch (error) {
        res.status(500).json({"response": "Transaction failed"});
        console.error(`Failed to submit transaction: ${error}`);
        process.exit(1);
    }
}

export default main;