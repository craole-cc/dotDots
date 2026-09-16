import json
import pathlib
import sys


def main() -> int:
    gateway_path = pathlib.Path(sys.argv[1])
    bridge_script = sys.argv[2]

    if gateway_path.exists():
        try:
            data = json.loads(gateway_path.read_text())
        except Exception:
            data = {}
    else:
        data = {}

    platforms = data.setdefault("platforms", {})
    whatsapp = platforms.setdefault("whatsapp", {})
    extra = whatsapp.setdefault("extra", {})
    extra["bridge_script"] = bridge_script

    gateway_path.write_text(json.dumps(data, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
