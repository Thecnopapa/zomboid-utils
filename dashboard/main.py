import os, sys, requests, subprocess, sqlite3
from flask import Flask, request, make_response, render_template, redirect, send_from_directory
from werkzeug.utils import secure_filename



print(" * Starting dashboard service...")

server_name=os.environ["ZOMBOID_SERVER"]
print(" * Server name:", server_name)

app = Flask(__name__)
app.secret_key = bytes(os.environ["FLASK_KEY"], "UTF-8")
admin_password=os.environ["DASHBOARD_PASSWORD"]

print(" * Flask initialised")



def parse_info(server_name, password=None):
    admin = False
    if password is not None:
        if password == admin_password:
            admin=True

    return {}



@app.route("/static/<file>")
def return_static(file):
    file = secure_filename(file)
    return send_from_directory("static", file)

@app.route("/")
def redirect_to_dashboard():
    return redirect("/dashboard")

@app.route("/dashboard")
def dashboard():
    #servers = [s.split(".")[0] for s in os.listdir("/home/server/Zomboid/Server") if s.endswith(".ini")]


    info = parse_info(server_name)
    return render_template("dashboard.html", info=info)

@app.post("/restart/<server>")
def restart_server(server):
    password = request.headers.get("Authentication", None)
    if password == restart_password:
        server = secure_filename(server)
        assert f"{server}.ini" in os.listdir("/home/server/Zomboid/Server")
        cmd = f'tmux send-keys C-c " zomboid-start -servername {server}" "Enter"' 
        print("$", cmd)
        subprocess.run(cmd,shell=True, check=True)
        return "", 200
    else:
        return "", 403








if __name__ == "__main__":
    app.run(port=8080, host="0.0.0.0", debug="--debug" in sys.argv, ssl_context=("./certificates/cert.pem", "./.secrets/key.pem"))


