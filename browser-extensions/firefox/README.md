# CTB query browser extension

## Introduction

This extension queries the HLCTB network hosted on digitalocean and checks whether the certificate for domain opened in browser is `present and valid` or `not`.

#### Possible responses

- When the certificate of domain matches the certificate present on HLCTB
`Valid certificate: present on ctb network ${domain}`

- When the certificate has been present for domain
`Certificate has been revoked ${domain}`

- WHen a new certificate has been issued for domain
`Invalid cert for ${domain}`

- When HLCTB doesn't have any certificate for domain
`Entry not available for ${domain}`

- When response from server doesn't match any of the above cases
`Problem with Server for ${domain}: ${this.response} ${this.readyState}`

## Installation

Install dependencies:
```
yarn install # or npm install
```

## Usage
To run a development server that will watch for file changes and rebuild the scripts, run:
```
yarn start
```

To just build the files without the development server:
```
yarn build
```

Both commands will create a `dist/` directory, it will contain the built files that should be loaded into the browser or packed.

For instructions on how to load an unpacked extension, refer [this](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Temporary_Installation_in_Firefox).