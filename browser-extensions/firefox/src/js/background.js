var log = console.log.bind(console)
var ALL_SITES = { urls: ['<all_urls>'] }

var extraInfoSpec = ['blocking'];

browser.webRequest.onHeadersReceived.addListener(async function(details){
    log(`\n\nGot a request for ${details.url} with ID ${details.requestId}`)
    var requestId = details.requestId

    var securityInfo = await browser.webRequest.getSecurityInfo(requestId, {
        certificateChain: false,
        rawDER: false
    });

    let cert = securityInfo.certificates[0];
    let sha256 = cert.fingerprint.sha256;

    let obj = {};
    cert.subject.split(",").forEach(function(ele){
        let key = ele.split("=")[0]
        let val = ele.split("=")[1]
        obj[key] = val;
    })
    loadDoc(`http://134.209.145.224:8000/query/queryCertificate?subjectName=${obj["CN"]}`, obj["CN"], sha256)
}, ALL_SITES, extraInfoSpec)


function loadDoc(url, domain, fingerprint) {
    console.log(domain)
    var xhttp;
    xhttp=new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
      if (this.readyState == 4 && this.status == 200) {

        verifyCert(this, domain, fingerprint);

      }else if (this.readyState == 4 && this.status == 404) {

        if(this.response['response']){
            createNotification(`${this.response['response']} for ${domain}`)
        }

      }else if(this.readyState == 4) {
        let msg=`Problem with Server for ${domain}: ${this.response} ${this.readyState}`
        createNotification(msg)
      }
    }

    xhttp.open("GET", url, true);
    xhttp.responseType = 'json';
    xhttp.send();
}

function verifyCert(obj,domain, fingerPrint){
    console.log(obj.response)
    let jsonObj = obj.response

    let msg = "";
    if(jsonObj["fingerPrint"]){
        let netFingerPrint = jsonObj["fingerPrint"]
        if(netFingerPrint == fingerPrint){
            if (jsonObj['revokeStatus'] == "notRevoked"){
            msg = `Valid certificate: present on ctb network ${domain}`
            }else {
            msg = `Certificate has been revoked ${domain}`
            }
        }else {
            msg = `Invalid cert for ${domain}`
        }
    }
    createNotification(msg)
}

function createNotification(msg){
    console.log(msg)
    browser.notifications.create("ctbResponse", {
        "type": "basic",
        "title": `Query result from HLCTB`,
        "message": msg
      });
}

