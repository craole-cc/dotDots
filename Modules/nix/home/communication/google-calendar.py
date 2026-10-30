"""Keep Google credentials and generated sync configuration outside the store.

Usage: google-calendar.py VDIRSYNCER [ARGS...]

ARGS default to "sync". "setup" runs discover and sync, then marks the setup
as ready so the systemd timer starts doing work.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

REQUIRED_CLIENT_KEYS = ("client_id", "client_secret")


def xdg(variable, fallback):
    """Resolve an XDG directory, treating an empty variable as unset."""
    return Path(os.environ.get(variable) or fallback)


def load_client(credentials):
    if not credentials.is_file():
        sys.exit(f"Save Google's Desktop OAuth client JSON to {credentials} with mode 0600 first.")
    if credentials.stat().st_mode & 0o077:
        sys.exit(f"Run chmod 600 {credentials} before continuing.")
    try:
        document = json.loads(credentials.read_text())
    except (OSError, json.JSONDecodeError) as error:
        sys.exit(f"Cannot read {credentials}: {error}")
    client = document.get("installed") if isinstance(document, dict) else None
    if not isinstance(client, dict):
        sys.exit(
            f"{credentials} has no 'installed' section. "
            "Create the OAuth client in Google Cloud as a 'Desktop app', not a web client."
        )
    missing = [key for key in REQUIRED_CLIENT_KEYS if not client.get(key)]
    if missing:
        sys.exit(f"{credentials} is missing: {', '.join(missing)}.")
    return client


def write_private(path, text):
    """Create the file as 0600 from the start, fixing the mode if it already existed."""
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w") as stream:
        os.fchmod(stream.fileno(), 0o600)
        stream.write(text)


def render_config(client, state, data):
    # vdirsyncer reads each value as JSON, so json.dumps is the right quoting.
    quote = json.dumps
    return f"""[general]
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
"""


def run(base, arguments):
    try:
        subprocess.run(base + arguments, check=True)
    except FileNotFoundError:
        sys.exit(f"Cannot execute {base[0]}.")
    except subprocess.CalledProcessError as error:
        sys.exit(f"{base[0]} {' '.join(arguments)} failed with exit status {error.returncode}.")


def main():
    if len(sys.argv) < 2:
        sys.exit(f"Usage: {Path(sys.argv[0]).name} VDIRSYNCER [ARGS...]")
    os.umask(0o077)  # also inherited by vdirsyncer, so its token file is private
    home = Path.home()
    config = xdg("XDG_CONFIG_HOME", home / ".config")
    state = xdg("XDG_STATE_HOME", home / ".local/state") / "vdirsyncer"
    data = xdg("XDG_DATA_HOME", home / ".local/share") / "calendars/google"

    client = load_client(config / "vdirsyncer/google-client.json")
    for directory in (state, data):
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)

    runtime_config = state / "google.config"
    write_private(runtime_config, render_config(client, state, data))

    base = [sys.argv[1], "--config", str(runtime_config)]
    command = sys.argv[2:] or ["sync"]
    if command == ["setup"]:
        run(base, ["discover", "google"])
        run(base, ["sync", "google"])
        (state / "google.ready").touch(mode=0o600)
    else:
        run(base, command)


if __name__ == "__main__":
    main()
