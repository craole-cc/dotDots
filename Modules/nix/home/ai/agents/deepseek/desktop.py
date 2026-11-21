"""Start the owned Web backend and hand its authenticated URL to an app window."""

import os
from pathlib import Path
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request


def startup_url(text, port):
    match = re.search(rf"^dsh web: (http://127\.0\.0\.1:{port}/\S*)", text, re.MULTILINE)
    return match.group(1) if match else None


def main():
    systemctl, browser, port = sys.argv[1:4]
    runtime = Path(os.environ["XDG_RUNTIME_DIR"]) / "deepseek-web"
    subprocess.run([systemctl, "--user", "start", "deepseek-web.service"], check=True)
    deadline = time.monotonic() + 90
    # Do not send the one-time authentication URL to the readiness probe.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    while time.monotonic() < deadline:
        try:
            url = startup_url((runtime / "startup.log").read_text(), port)
            if url:
                try:
                    with opener.open(f"http://127.0.0.1:{port}/", timeout=1):
                        pass
                except urllib.error.HTTPError as error:
                    if error.code != 401:
                        raise
                state = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
                os.execv(browser, [
                    browser, f"--user-data-dir={state / 'deepseek-harness-browser'}",
                    "--class=deepseek-harness", f"--app={url}",
                ])
        except (OSError, urllib.error.URLError):
            pass
        time.sleep(0.25)
    raise SystemExit("DeepSeek did not become ready. Check systemctl --user status deepseek-web.")


if __name__ == "__main__":
    main()
