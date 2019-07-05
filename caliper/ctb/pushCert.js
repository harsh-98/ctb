/*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

'use strict';

// const crypto = require('crypto');
const path = require('path');
const fs = require('fs');

module.exports.info  = 'publishing digital items';

let bc, contx;
let itemBytes = 1024;   // default value
let ids = [];
let num = 0;

module.exports.ids = ids;

module.exports.init = function(blockchain, context, args) {

    bc       = blockchain;
    contx    = context;

    return Promise.resolve();
};

module.exports.run = function() {
    num++;
    let issueCount = 1;
    let subDomain = "sub";
    let rootDomain = "example.com";
    let domain = `${subDomain}${num}.${rootDomain}-${issueCount}`;
    let ca = `${subDomain}.${rootDomain}`;

    // console.log(path.resolve(__dirname));

    let certPath = path.resolve(__dirname,`../../net_testing/${domain}/${domain}.crt`);
    let intermediateCertPath = path.resolve(__dirname,`../../net_testing/${ca}/${ca}.crt`);
    let sigFilePath = "";

    let certString = fs.readFileSync(certPath).toString();
    let intermediateCertString = fs.readFileSync(intermediateCertPath).toString();
    var sigString = "";
    if (sigFilePath) {
        sigString = fs.readFileSync(sigFilePath).toString();
    }

    let fcn = "addCertificate";

    let args = {
            verb : fcn,
            domain: certString,
            ca: intermediateCertString,
            sig: sigString
        };

    return bc.invokeSmartContract(contx, 'mycc', 'v0', args, 120)
        .then(results => {
            for (let result of results){
                if(result.IsCommitted()) {
                    ids.push(result.GetResult().toString());
                }
            }
            return Promise.resolve(results);
        });
};

module.exports.end = function() {
    return Promise.resolve();
};
