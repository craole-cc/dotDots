"""Focus the DeepSeek workspace and start any missing app windows."""

import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import time


WORKSPACE = "AI-Deepseek"
HARNESS_CLASSES = {"deepseek-harness", "chrome-127.0.0.1__-Default"}
CHAT_CLASSES = {"deepseek-chat", "chrome-chat.deepseek.com__-Default"}


def query(*command):
    return json.loads(subprocess.check_output(command, timeout=5))


def focus_and_inspect():
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        subprocess.run(
            ["hyprctl", "dispatch", f'hl.dsp.focus({{ workspace = "name:{WORKSPACE}" }})'],
            check=True, stdout=subprocess.DEVNULL, timeout=5,
        )

        def classes():
            return {
                window["class"]
                for window in query("hyprctl", "-j", "clients")
                if window["workspace"]["name"] == WORKSPACE
            }

    elif os.environ.get("NIRI_SOCKET"):
        subprocess.run(
            ["niri", "msg", "action", "focus-workspace", WORKSPACE],
            check=True, stdout=subprocess.DEVNULL, timeout=5,
        )
        workspace_id = next(
            workspace["id"]
            for workspace in query("niri", "msg", "--json", "workspaces")
            if workspace["name"] == WORKSPACE
        )

        def classes():
            return {
                window["app_id"]
                for window in query("niri", "msg", "--json", "windows")
                if window["workspace_id"] == workspace_id
            }

    else:
        raise SystemExit("deepseek-workspace requires a Hyprland or Niri session.")
    return classes


def main():
    desktop, chat = sys.argv[1:]
    lock_path = Path(os.environ["XDG_RUNTIME_DIR"]) / "deepseek-workspace.lock"
    with lock_path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return

        classes = focus_and_inspect()
        current = classes()
        pending = [
            (app_classes, subprocess.Popen([launcher]))
            for app_classes, launcher in [(HARNESS_CLASSES, desktop), (CHAT_CLASSES, chat)]
            if current.isdisjoint(app_classes)
        ]

        # Keep the lock until the compositor sees the windows. Harness may
        # need to wait for its backend before Chromium opens.
        deadline = time.monotonic() + 95
        while pending and time.monotonic() < deadline:
            time.sleep(0.5)
            current = classes()
            pending = [
                (app_classes, process)
                for app_classes, process in pending
                if current.isdisjoint(app_classes) and process.poll() in (None, 0)
            ]


if __name__ == "__main__":
    main()
