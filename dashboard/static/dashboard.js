    

    async function requestRestart(serverName){
        let passwordInput = document.querySelector("#password-input");
        let resp = await fetch("/restart/"+serverName,  {
            method:"POST",
            headers:{
                "Authentication": passwordInput.value,
            }
        });
        console.log(resp);
    }