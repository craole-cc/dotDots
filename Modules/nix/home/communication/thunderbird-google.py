"""Configure Gmail and Google calendars from a private runtime environment file."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import tempfile
from urllib.parse import quote, unquote
import uuid

DEFAULT_ID = "dotdotsGoogle"
CALDAV_ROOT = "https://apidata.googleusercontent.com/caldav/v2/"
ENVIRONMENT_KEYS = {"GOOGLE_EMAIL", "GOOGLE_REAL_NAME", "GOOGLE_CALENDAR_IDS"}
EMAIL_PATTERN = re.compile(r"[^\s@]+@[^\s@]+\.[^\s@]+")
PREF_LINE = re.compile(r'^user_pref\(("(?:[^"\\]|\\.)*"), (.*)\);$')


def read_environment(path):
    if not path.is_file():
        raise ValueError(f"Create {path} from google.env.example and chmod 600 it first.")
    if path.stat().st_mode & 0o077:
        raise ValueError(f"Run chmod 600 {path} before continuing.")
    values = {}
    for number, line in enumerate(path.read_text().splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        key = key.strip()
        if not separator or key not in ENVIRONMENT_KEYS:
            raise ValueError(f"Unsupported environment entry on line {number}.")
        value = value.strip()
        if value.startswith(("'", '"')):
            if len(value) < 2 or value[-1] != value[0]:
                raise ValueError(f"Unmatched quotes on line {number}.")
            value = value[1:-1]
        values[key] = value
    if not EMAIL_PATTERN.fullmatch(values.get("GOOGLE_EMAIL", "")):
        raise ValueError("Set GOOGLE_EMAIL to your Google account address.")
    return values


def split_pref(line):
    """Return (key, raw_value) for a user_pref line, or None for any other line."""
    match = PREF_LINE.match(line)
    if not match:
        return None
    try:
        return json.loads(match[1]), match[2]
    except json.JSONDecodeError:
        return None


def read_prefs(text):
    prefs = {}
    for line in text.splitlines():
        parsed = split_pref(line)
        if parsed:
            try:
                prefs[parsed[0]] = json.loads(parsed[1])
            except json.JSONDecodeError:
                pass
    return prefs


def first_id(existing, prefix, suffix, matches):
    """Name of the first existing mail.* entry whose value matches, else the default."""
    return next((key.split(".")[2] for key, value in existing.items()
                 if key.startswith(prefix) and key.endswith(suffix) and matches(value)),
                DEFAULT_ID)


def append_item(prefs, existing, key, item, separator):
    items = str(prefs.get(key, existing.get(key, ""))).split(separator)
    prefs[key] = separator.join(dict.fromkeys(value for value in items + [item] if value))


def add_calendars(prefs, existing, values, identity):
    email = values["GOOGLE_EMAIL"]
    calendar_ids = values.get("GOOGLE_CALENDAR_IDS") or email
    for calendar_id in dict.fromkeys(item.strip() for item in calendar_ids.split(",") if item.strip()):
        uri = CALDAV_ROOT + quote(calendar_id, safe="") + "/events/"
        wanted = unquote(uri).rstrip("/")
        # Reuse a calendar registered earlier (by this script or by hand) for the same URI.
        calendar = next((key.split(".")[2] for key, value in existing.items()
                         if key.startswith("calendar.registry.") and key.endswith(".uri")
                         and unquote(str(value)).rstrip("/") == wanted),
                        str(uuid.uuid5(uuid.NAMESPACE_URL, "google-calendar:" + calendar_id)))
        prefix = f"calendar.registry.{calendar}."
        prefs.update({
            prefix + "type": "caldav",
            prefix + "uri": uri,
            prefix + "name": "Google: " + calendar_id,
            prefix + "username": email,
            prefix + "imip.identity.key": identity,
            prefix + "disabled": False,
            prefix + "readOnly": False,
            prefix + "cache.enabled": True,
        })
        append_item(prefs, existing, "calendar.list.sortOrder", calendar, " ")


def build_prefs(existing, values):
    email = values["GOOGLE_EMAIL"]
    # Reuse a matching account left by Home Manager or manual setup.
    identity = first_id(existing, "mail.identity.", ".useremail", lambda value: value == email)
    account = first_id(existing, "mail.account.", ".identities",
                       lambda value: identity in str(value).split(","))
    server = existing.get(f"mail.account.{account}.server", DEFAULT_ID)
    smtp = existing.get(f"mail.identity.{identity}.smtpServer", DEFAULT_ID)
    prefs = {
        f"mail.account.{account}.identities": existing.get(f"mail.account.{account}.identities") or identity,
        f"mail.account.{account}.server": server,
        f"mail.identity.{identity}.useremail": email,
        f"mail.identity.{identity}.fullName": values.get("GOOGLE_REAL_NAME") or email,
        f"mail.identity.{identity}.smtpServer": smtp,
        f"mail.identity.{identity}.valid": True,
        f"mail.server.{server}.type": "imap",
        f"mail.server.{server}.hostname": "imap.gmail.com",
        f"mail.server.{server}.userName": email,
        f"mail.server.{server}.name": email,
        f"mail.server.{server}.port": 993,
        f"mail.server.{server}.socketType": 3,
        f"mail.server.{server}.authMethod": 10,
        f"mail.server.{server}.login_at_startup": True,
        f"mail.server.{server}.check_new_mail": True,
        f"mail.smtpserver.{smtp}.hostname": "smtp.gmail.com",
        f"mail.smtpserver.{smtp}.username": email,
        f"mail.smtpserver.{smtp}.port": 465,
        f"mail.smtpserver.{smtp}.try_ssl": 3,
        f"mail.smtpserver.{smtp}.authMethod": 10,
    }
    append_item(prefs, existing, "mail.accountmanager.accounts", account, ",")
    append_item(prefs, existing, "mail.smtpservers", smtp, ",")
    prefs["mail.accountmanager.defaultaccount"] = existing.get("mail.accountmanager.defaultaccount") or account
    prefs["mail.smtp.defaultserver"] = existing.get("mail.smtp.defaultserver") or smtp
    add_calendars(prefs, existing, values, identity)
    return prefs


def merge_prefs(original, prefs):
    """Keep unrelated preferences and replace ours without duplicates."""
    retained = []
    for line in original.splitlines():
        parsed = split_pref(line)
        if parsed is None or parsed[0] not in prefs:
            retained.append(line)
    generated = "\n".join(
        f"user_pref({json.dumps(key)}, {json.dumps(value)});"
        for key, value in sorted(prefs.items())
    )
    return "\n".join(retained).rstrip() + "\n" + generated + "\n"


def save(profile, path, original, result):
    """Keep the original profile for recovery and replace prefs atomically."""
    backup = profile / "prefs.js.before-google-setup"
    if not backup.exists():
        with backup.open("x") as stream:
            stream.write(original)
    with tempfile.NamedTemporaryFile(mode="w", dir=profile, delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(result)
    try:
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def configure(profile, values):
    # Thunderbird's own lock files; main() separately holds a POSIX lock on .parentlock.
    if any((profile / name).exists() or (profile / name).is_symlink()
           for name in ("lock", "parent.lock")):
        raise ValueError("Close Thunderbird and release its profile lock before setup.")
    path = profile / "prefs.js"
    if path.is_symlink():
        raise ValueError("prefs.js must be a writable profile file, not a symlink.")
    original = path.read_text() if path.exists() else ""
    prefs = build_prefs(read_prefs(original), values)
    save(profile, path, original, merge_prefs(original, prefs))


def main():
    os.umask(0o077)
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--env", type=Path, default=config_home / "thunderbird/google.env")
    parser.add_argument("--profile", type=Path, default=Path.home() / ".thunderbird/google")
    args = parser.parse_args()
    try:
        values = read_environment(args.env)
        if not args.profile.is_dir():
            raise ValueError("Open Thunderbird's google profile once, then close it before setup.")
        lock_path = args.profile / ".parentlock"
        if lock_path.is_symlink():
            raise ValueError("The profile's .parentlock must not be a symlink.")
        # Mozilla retains this file after exit; hold its POSIX lock while writing.
        with lock_path.open("a+") as lock:
            try:
                fcntl.lockf(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError as error:
                raise ValueError("Close Thunderbird before running setup.") from error
            configure(args.profile, values)
    except (ValueError, OSError) as error:
        parser.exit(1, f"{error}\n")
    print("Google mail and calendars configured. Open Thunderbird and complete Google sign-in.")


if __name__ == "__main__":
    main()
