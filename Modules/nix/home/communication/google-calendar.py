"""Keep Google credentials and generated sync configuration outside the store."""
import json
import os
from pathlib import Path
import subprocess
import sys

os.umask(0o077)
home = Path.home()
config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
state = Path(os.environ.get("XDG_STATE_HOME", home / ".local/state")) / "vdirsyncer"
data = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "calendars/google"
credentials = config / "vdirsyncer/google-client.json"
if not credentials.is_file():
    sys.exit(f"Save Google's Desktop OAuth client JSON to {credentials} with mode 0600 first.")
if credentials.stat().st_mode & 0o077:
    sys.exit(f"Run chmod 600 {credentials} before continuing.")
client = json.loads(credentials.read_text())["installed"]
state.mkdir(parents=True, exist_ok=True, mode=0o700)
data.mkdir(parents=True, exist_ok=True, mode=0o700)
quote = json.dumps
runtime_config = state / "google.config"
runtime_config.write_text(f'''[general]
status_path = {quote(str(state / "status"))}
[pair google]
a = "google_remote"
b = "google_local"
collections = ["from a"]
[storage google_remote]
type = "google_calendar"
read_only = true
token_file = {quote(str(state / "google-token.json"))}
client_id = {quote(client["client_id"])}
client_secret = {quote(client["client_secret"])}
[storage google_local]
type = "filesystem"
path = {quote(str(data))}
fileext = ".ics"
''')
runtime_config.chmod(0o600)
command = sys.argv[2:] or ["sync"]
base = [sys.argv[1], "--config", str(runtime_config)]
if command == ["setup"]:
    for args in (["discover", "google"], ["sync", "google"]):
        subprocess.run(base + args, check=True)
    (state / "google.ready").touch(mode=0o600)
else:
    subprocess.run(base + command, check=True)
