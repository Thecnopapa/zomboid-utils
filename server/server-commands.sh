echo "Sourcing commands.sh ..."


zomboid-start (){
	tmux send -t zomboid.0 "echo \" * Starting Zomboid server... ($1)\"" 'Enter'
    zomboid-update
    dns-update
    tmux send -t zomboid.1 'cd ~/pzserver' 'Enter'
    echo "./start-server.sh -servername \"$1\""
    tmux send -t zomboid.1 "./start-server.sh -servername \"$1\"" 'Enter'
}

zomboid-validate (){
	tmux send -t zomboid.0 'echo " * Updating and Validating Zomboid installation..."' 'Enter'
	tmux send -t zomboid.1 'steamcmd +force_install_dir /home/server/pzserver/ +@sSteamCmdForcePlatformType linux +login anonymous +app_update 380870 validate +quit' 'Enter'
	tmux send -t zomboid.0 'echo " * Update and Validation finished"' 'Enter'
}

zomboid-update (){
	tmux send -t zomboid.0 'echo " * Updating Project Zomboid..."' 'Enter'
	tmux send -t zomboid.1 'steamcmd +force_install_dir /home/server/pzserver/ +@sSteamCmdForcePlatformType linux +login anonymous +app_update 380870 +quit' 'Enter'
	tmux send -t zomboid.0 'echo " * Update finished"' 'Enter'
}

zomboid-stop (){
	tmux send -t zomboid.0 'echo " * Stopping Zomboid server"' 'Enter'
	tmux send -t zomboid.1 C-c 'Enter'
}

