# Caliper
Caliper is a blockchain performance benchmark framework, which allows users to test different blockchain solutions with predefined use cases, and get a set of performance test results.


## Node 8+,9+
Refering [issue](https://github.com/hyperledger/caliper/issues/478), caliper is compatible with node version 8 and 9. Also pm2 and verdaccio(local npm package registry)  should be installed.
```
nvm install v8.16.0
nvm use v8.16.0
npm install
npm run repoclean
npm run bootstrap
npm install -g verdaccio@2.6.4
npm install -g pm2@2.10.1

cat <<EOF > ~/.npmrc
//localhost:4873/:_authToken="foo"
fetch-retries=10
EOF

cd packages/caliper-tests-integration/

verdaccio -c scripts/config.yaml # on terminal 1
node ./scripts/npm_serve # on terminal 2


```
## References:

- https://medium.com/tallyx/adapting-hyperledger-caliper-to-custom-hyperledger-fabric-networks-3ffa650215a0
- https://hyperledger.github.io/caliper/docs/1_Getting_Started.html
- https://github.com/hyperledger/caliper/
