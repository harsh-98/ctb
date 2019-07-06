/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const ccpPath = path.resolve(__dirname, 'connect.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

async function main() {
    var args = process.argv.slice(2);
    let username = args[0];

    var certPath = args[1];
    var intermediateCertPath = args[2];
    var sigFilePath = null;
    var revoke = null;
    if (args.length === 4) {
        sigFilePath = args[3];
    }
    if (args.length === 5) {
        sigFilePath = args[3];
        revoke = args[4];
        console.log(revoke);
    }
    var certString = fs.readFileSync(certPath).toString();
    var intermediateCertString = fs.readFileSync(intermediateCertPath).toString();
    var sigString = "";
    if (sigFilePath !== null) {
        sigString = fs.readFileSync(sigFilePath).toString();
    }

    let tx_id = "mycc";
    if (revoke === null) {
            var request = {
        //targets: let default to the peer assigned to the client
            chaincodeId: 'mycc',
            fcn: 'addCertificate',
            args: [certString, intermediateCertString, sigString],
            chainId: 'mychannel',
            txId: tx_id
        };
    } else if (revoke === 'revoke') {
          var request = {
        //targets: let default to the peer assigned to the client
            chaincodeId: 'mycc',
            fcn: 'revokeCertificate',
            args: [certString, intermediateCertString, sigString],
            chainId: 'mychannel',
            txId: tx_id
        };
    }
    try {
        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

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
        const contract = network.getContract(request.txId);

        // Submit the specified transaction.
        // addCertificate transaction - requires 2 args, ex: ('addCertificate', '','')
        // addCertificate transaction - requires 3 args, ex: ('addCertificate', '','','')
        // revokeCertificate transaction - requires 3 args , ex: ('revokeCertificate', '','','')
        await contract.submitTransaction(request.fcn, ...request.args);
        console.log('Transaction has been submitted');

        // Disconnect from the gateway.
        await gateway.disconnect();

    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
        process.exit(1);
    }
}

main();
