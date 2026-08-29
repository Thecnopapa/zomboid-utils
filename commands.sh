echo "Sourcing commands.sh ..."


zomboid-start (){
	tmux -t 0 'echo " * Starting Zomboid server... ($1)"'
    zomboid-update
    dns-update
    cd ~/pzserver
    ./start-server.sh "$1"
    cd $ZOMBOID_FOLDER
    tmux -t 0 'echo " * Server STOPPED"'
}

zomboid-verify (){
	echo " * Updating and Verifying Zomboid installation..."
	steamcmd +force_install_dir /home/server/pzserver/ +@sSteamCmdForcePlatformType linux +login anonymous +app_update 380870 validate +quit
	tmux -t 0 'echo " * Update finished"'
}

zomboid-update (){
	tmux -t 0 'echo " * Updating Project Zomboid..."'
	steamcmd +force_install_dir /home/server/pzserver/ +@sSteamCmdForcePlatformType linux +login anonymous +app_update 380870 +quit
	tmux -t 0 'echo " * Update finished"'
}

zomboid-stop (){
	tmux -t 0 'echo " * Stopping Zomboid server"'
}

