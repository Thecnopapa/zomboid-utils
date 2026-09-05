import os, sys, requests, subprocess, sqlite3
from flask import Flask, request, make_response, render_template, redirect, send_from_directory
from werkzeug.utils import secure_filename



print(" * Starting dashboard service...")

server_name=os.environ["ZOMBOID_SERVER"]
print(" * Server name:", server_name)

app = Flask(__name__)
app.secret_key = bytes(os.environ["FLASK_KEY"], "UTF-8")
admin_login=os.environ["DASHBOARD_LOGIN"]
admin_password=os.environ["DASHBOARD_PASSWORD"]
secrets_folder=os.environ["SECRETS_PATH"]
save_folder=os.environ["SAVE_FOLDER"]


print(" * Flask initialised")


class Info(object):
    def __init__(self, data):
        self.data = data

    def __getitem__(self, key):
        return self.data.get(key, None)

    def __getattr__(self, key):
        return self.data.get(key, None)

def parse_info():
    info = {
        "user":None,
        "admin": False,
        "status": None,
        "status_int": None,
        "server_name": None
    }
    with open(os.path.join(secrets_folder, "status")) as f:
        status_int = int(f.read().replace("\n", "").strip())
    print(" * Server status:", status_int)
    info["status_int"] = status_int
    if status_int == 0:
        info["status"] = "stopped"
    elif status_int == 1:
        info["status"] = "running"
    elif status_int == 2:
        info["status"] = "starting"
    elif status_int == 3:
        info["status"] = "stopping"

    with open(os.path.join(secrets_folder, "server-name.sh")) as f:
        info["server_name"] = f.read().split("=")[-1].replace("\n", "").replace('"', "").strip()
    info["servers"] = [s.split(".")[0] for s in os.listdir(os.path.join(save_folder, "Server")) if s.endswith(".ini")]
    if check_auth():
        info["user"] = request.cookies.get("user")
        info["admin"] = True
    info = Info(info)
    return info



@app.route("/static/<file>")
def return_static(file):
    file = secure_filename(file)
    return send_from_directory("static", file)

@app.get("/")
def redirect_to_dashboard():
    return redirect("/dashboard")

@app.get("/dashboard")
def dashboard():
    info = parse_info()
    return render_template("dashboard.html", info=info)

@app.post("/api/server/<command>")
def restart_server(command):
    info = parse_info()
    if info.admin:
        try:
            if command == "restart":
                run_command("restart")
            elif command == "start":
                run_command("start")
            elif command == "update":
                run_command("update")
            elif command == "validate":
                run_command("validate")
            elif command == "stop":
                run_command("stop")
            elif command == "unstuck":
                run_command("echo")
            elif command == "change":
                name = request.get_json().get("serverName")
                run_command(f"change-server {name}")
            else:
                raise
            return "", 200
        except Exception as e:
            print(e)
            return "", 400
    else:
        if info.status == "stopped" and command == "start":
            run_command("start")
            return "", 200
        else:
            return "", 403


@app.route("/login")
def login_page():
    return render_template("login.html")

def run_command(command):
    try:
        print("$", command)
        subprocess.run(f"source $ZOMBOID_FOLDER/setup.sh && ({command} &)", shell=True, check=True, env=os.environ, executable='/bin/bash')
        return True
    except Exception as e:
        print(e)
        raise
        return False


@app.before_request
def before_request():
    if not request.is_secure:
        url = request.url.replace('http://', 'https://', 1)
        code = 301
        return redirect(url, code=code)

@app.post("/api/login")
def login_request():
    print(dir(request))
    data = request.form
    user = data.get("user")
    password = data.get("password")
    print(data)
    if check_auth(user, password):
        resp = redirect("/")
        resp.set_cookie("user", user)
        resp.set_cookie("password", password)
        return resp, 303
    else:
        resp = redirect("/login")
        return resp, 403

@app.route("/logout")
def logout():
    resp = redirect("/login")
    resp.delete_cookie("user")
    resp.delete_cookie("password")
    return resp, 303




def check_auth(user=None, password=None):
    if user is None and password is None:
        user = request.cookies.get("user", None)
        password = request.cookies.get("password", None)
    if user == admin_login:
        if password==admin_password:
            print(" * Auth succesfull:", user)
            return True
    return False



@app.route("/.well-known/acme-challenge/GvVhO8NN5wueX9CeYZqcc5lQk5cPIuNM9pufWDRvfT4")
def cert_validation():
    print("validation")
    return "GvVhO8NN5wueX9CeYZqcc5lQk5cPIuNM9pufWDRvfT4.FF_IxvzOvME6_h4DWWE1yTt64W251S4xHZznxQmWi_A", 200
    with open(os.path.join("static", "certificate.punchsalad.cert")) as cert:
        print(cert.read())
        return cert.read()
    #return send_from_directory("static", "certificate.punchsalad.cert")


if __name__ == "__main__":
    app.run(port=8080, host="0.0.0.0", debug="--debug" in sys.argv, ssl_context=("./certificates/cert.pem", os.path.join(secrets_folder, "key.pem")))


