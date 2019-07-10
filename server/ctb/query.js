/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const forge = require('node-forge')
const { pki, md } = forge
require('dotenv').config()

const ccpPath = path.resolve(__dirname, 'connect.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

export default async function query(req, res, next) {
    try {
        let username = process.env.QUERYUSER;
        let CHAINCODE = process.env.CHAINCODE;
        let CHANNEL = process.env.CHANNEL;

        let subjectName =  req.query.subjectName;
        let fcn = req.params.fcn;

        if (!['queryCertificate', 'queryCertificateHistory'].includes(fcn)) {
            return res.status(400).json({'response': 'Bad function name'});
        }

        // load keys for "username"
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
        const network = await gateway.getNetwork(CHANNEL);

        // Get the contract from the network.
        const contract = network.getContract(CHAINCODE);

        // Evaluate the specified transaction.
        // queryCertificate transaction - requires 1 argument, ex: ('queryCertificate', 'example.com')
        // queryCertificateHistory transaction - requires 1 arguments, ex: ('queryCertificateHistory', 'domain.com')
        let result = "{}";
        try {
            result = await contract.evaluateTransaction(fcn, subjectName);
        } catch (error) {
            return res.status(404).json({"response": "Entry Not available"});
        }
        let certInfo = JSON.parse(result.toString());
        // let cert = certInfo['certString']

        let certBuf = Buffer.from(certInfo['certString'], 'utf8')
        const cert = pki.certificateFromPem(certBuf);
        const der = forge.asn1.toDer(pki.certificateToAsn1(cert)).getBytes();
        const m = md.sha256.create();
        m.start();
        m.update(der);
        const fingerprint = m.digest()
      .toHex()
      .match(/.{2}/g)
      .join(':')
      .toUpperCase();
        console.log(fingerprint)
        certInfo['fingerPrint'] = fingerprint

        res.status(200).json(certInfo);
    } catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        process.exit(1);
    }
}

