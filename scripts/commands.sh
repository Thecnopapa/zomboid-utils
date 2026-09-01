

zomboid-console(){
	echo " * Initialising Zomboid..."
	check-tmux && zomboid-tmux
	source $ZOMBOID_FOLDER/scripts/commands.sh
	tmux a -t zomboid
}

zomboid-tmux (){
	echo " * Starting zomboid Tmux session"
	tmux new-session -s zomboid -d -n server \
	&& $(tmux split-window -h -d && \
	tmux send -t zomboid.0 "cd $ZOMBOID_FOLDER" 'Enter' && \
	tmux send -t zomboid.0 "source ./setup.sh" 'Enter' && \
	tmux send -t zomboid.0 "source ./server/server-commands.sh" 'Enter' && \
	tmux send -t zomboid.1 "cd $PZ_INSTALLATION" 'Enter') || return 1
	echo " * Tmux session ready"
	return 0
}

start (){
	echo " * Starting Project Zomboid server..."
	export SERVER_STATUS=2
	check-tmux && echo " * Starting Tmux"; zomboid-tmux || echo " * Server already running"
	check-zomboid && echo " * Starting new server" && tmux send -t zomboid.0 "zomboid-start " "$ZOMBOID_SERVER" 'Enter' || echo " * Server already running"
	check-zomboid
	export SERVER_STATUS=$?
}

stop () {
	echo "bbb"

	check-tmux && echo " * Tmux Not running ($?)" && return 0 || echo " * Stopping Server.." && tmux send -t zomboid.0 "zomboid-stop" 'Enter'
	echo "aaaa"
	check-zomboid && echo " * Zomboid server was not running" && return 0
	while ! check-zomboid; do
		echo " * Waiting for server to stop..."
		sleep 1
	done
	echo " * Server STOPPED"
	check-zomboid
	export SERVER_STATUS=$?
	return 0
}

validate (){
	echo " * Validating Project Zomboid server..."
	stop
	check-tmux && echo " * Starting Tmux"; zomboid-tmux || echo " * Server already running"
	check-zomboid && echo " * Starting new server" && tmux send -t zomboid.0 "zomboid-validate " "$ZOMBOID_SERVER" 'Enter' || echo " * Server already running"
	start
}

restart (){
	echo " * Restarting Project Zomboid server..."
	stop && start || echo " * Failed to stop server"
}

check-zomboid (){
	echo " * Checking for running Zomboid server..."
	#echo $(pgrep "ProjectZomboid")
	if [[ -z $(pgrep "ProjectZomboid") ]]; then
		echo " * Server NOT running"
		return 0
	else 
		echo " * Server IS running"
		return 1
	fi 
}

check-tmux (){
	if [[ "$(tmux list-sessions |grep "zomboid" -c)" == "1" ]]; then
		echo " * Tmux session IS active"
		return 1
	else 
		echo " * Tmux session NOT active"
		return 0
	fi
}

zomboid-dashboard-debug (){
	cd "~/dashboard"
	python ./main.py --debug
}

zomboid-dashboard (){
	cd ~/dashboard
	gunicorn main:app --certfile ./certificates/cert.pem --keyfile ~/.secrets/key.pem -b 0.0.0.0:8080
}

dns-update(){
	echo " * Updating DNS Records..."
	python ~/scripts/update-dns.py -u
}


build (){
	sudo docker build . -t zomboid-server "$@"
}

run (){
	cd $ZOMBOID_FOLDER
	sudo docker run -it -v ~/Zomboid:/home/zombie/Zomboid -v ~/pzserver:/home/zombie/pzserver -v ./.secrets:/home/zombie/.secrets zomboid-server -p 16261:16261 -p 16262:16262
}



check-zomboid
export SERVER_STATUS=$?
