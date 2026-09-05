

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

update-vars(){
	check-tmux && echo " * Tmux not running" || tmux send -t zomboid.0 "source ./setup.sh" 'Enter' 
}
change-server(){
	if [[ $# -eq 1 ]]; then
		echo "export ZOMBOID_SERVER=\"$1\"" > $SECRETS_PATH/server-name.sh
		source $ZOMBOID_FOLDER/setup.sh
		update-vars
		return 0
	else
		echo " * Missing server name"
		return 1
	fi
}
update-status(){
	if [[ $# -eq 1 ]]; then
		echo $1 > $SECRETS_PATH/status
		echo " * Status set to $1"
	else
		echo " * New status not provided"
	fi

}

start (){
	echo " * Starting Project Zomboid server..."
	update-status 2
	check-tmux && echo " * Starting Tmux"; zomboid-tmux || echo " * Termux ready"
	check-zomboid && echo " * Starting new server" && tmux send -t zomboid.0 "zomboid-start " "$ZOMBOID_SERVER" 'Enter' || echo " * Server already running ($?)"
	check-zomboid
	status=$?
	echo "status=$?"
	while [ $status -ne 1 ] ; do
		echo " * Waiting for server to start... ($status)"
		sleep 1
		check-zomboid
		status=$?
	done
	check-zomboid
	update-status $?
}

stop () {
	update-status 3
	check-tmux && echo " * Tmux Not running ($?)" && return 0 || echo " * Stopping Server.." && tmux send -t zomboid.0 "zomboid-stop" 'Enter'
	
	check-zomboid && echo " * Zomboid server was not running"
	while ! check-zomboid; do
		echo " * Waiting for server to stop..."
		sleep 1
	done
	echo " * Server STOPPED"
	check-zomboid
	update-status $?
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
	pid="$(pgrep "ProjectZomboid")"
	if [[ -z "$pid" ]]; then
		echo " * Server NOT running"
		return 0
	else 
		if [[ -z $(ps -T -p $pid | grep "UdpEngine") ]]; then
			echo " * Server is STARTING ($pid/$(ps -T -p $pid | grep 'UdpEngine'))"
			return 2
		else
			echo " * Server IS running ($pid/$(ps -T -p $pid | grep 'UdpEngine'))"
			return 1
		fi
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
	cd "$ZOMBOID_FOLDER/dashboard"
	python ./main.py --debug
}

zomboid-dashboard (){
	cd $ZOMBOID_FOLDER/dashboard
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
update-status $?
