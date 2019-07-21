const initPopupScript = () => {
};
// function onGot(page){
//     console.log(page.message)
//     console.log(document.getElementsByTagName("p")[0].innerHTML)
//         console.log(document.getElementById("edit").innerHTML)// = page.message;
// }

// var getting = browser.runtime.getBackgroundPage();
// getting.then(onGot, ()=>{});
// browser.runtime.onMessage.addListener(function(message,sender,sendResponse) {
//     document.getElementById("edit").innerHTML = message;
//     sendResponse({msg:"This is a response message sent from the browser-action-popup"})
//     return true
// })

document.addEventListener('DOMContentLoaded', initPopupScript);
