    
let PROCESSING_REQUEST=false

async function serverStart(){
    serverCommand("start")
}

async function serverRestart(){
    serverCommand("restart")
}

async function serverStop(){
    serverCommand("stop")
}
async function serverUnstuck(){
    serverCommand("unstuck")
}

async function serverCommand(command){
    if (PROCESSING_REQUEST){
        return
    }
    PROCESSING_REQUEST=true
    let resp = await fetch("api/server/"+command, {
        method:"POST",
    });
    console.log(resp);
    if (resp.ok){
        setTimeout(function(){
           window.location.reload();
        }, 3000);
    } else {
        PROCESSING_REQUEST=false
    }
}