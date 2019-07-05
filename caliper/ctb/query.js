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

module.exports.info  = 'querying digital items';

let bc, contx;
let itemIDs;

module.exports.init = function(blockchain, context, args) {
    bc      = blockchain;
    contx   = context;

    return Promise.resolve();
};

module.exports.run = function() {
    let num  = Math.ceil(Math.random()*(100));
    let issueCount = 1;
    let subDomain = "sub";
    let rootDomain = "example.com";
    let domain = `${subDomain}${num}.${rootDomain}`;

    let args = {
        verb: 'queryCertificate',
        domain: domain
    };
    return bc.invokeSmartContract(contx, 'mycc', 'v0', args, 120);
};

module.exports.end = function() {
    return Promise.resolve();
};
