#!/bin/bash

if [[ "$1" == "--source" ]]; then 
    echo "Sourcing ~/.bashrc"
    source ~/.bashrc
fi
    
export SECRETS_PATH="$ZOMBOID_FOLDER/.secrets"
source $SECRETS_PATH/vars.sh
export SERVER_STATUS=0
source $ZOMBOID_FOLDER/scripts/commands.sh



if [[ "$1" == "--source" ]]; then 
    start
    zomboid-console
fi

