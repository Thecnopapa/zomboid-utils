#!/bin/bash

if [[ "$1" == "--source" ]]; then 
    echo "Sourcing ~/.bashrc"
    source ~/.bashrc
fi

export SAVE_FOLDER="$HOME/Zomboid"
export SECRETS_PATH="$ZOMBOID_FOLDER/.secrets"
source $SECRETS_PATH/vars.sh
source $SECRETS_PATH/server-name.sh
export SERVER_STATUS=0
source $ZOMBOID_FOLDER/scripts/commands.sh
echo " * Server name: $ZOMBOID_SERVER"



if [[ "$1" == "--source" ]]; then 
    start
    zomboid-console
fi

