"""Prepare Telegram-only runtime secrets without evaluating their values in Nix."""

import os
from pathlib import Path
import sys
import tempfile

from dotenv import dotenv_values


def prepare(source: Path, destination: Path) -> None:
    if source.resolve() == destination.resolve():
        raise ValueError("Telegram source and destination must differ")
    values = {
        key: value
        for key, value in dotenv_values(source, interpolate=False).items()
        if key.startswith("TELEGRAM_") and value is not None
    }
    if not values.get("TELEGRAM_BOT_TOKEN") or not values.get("TELEGRAM_ALLOWED_USERS"):
        raise ValueError("Telegram token and allowed users must both be configured")
    if values.get("TELEGRAM_ALLOW_ALL_USERS", "").lower() in {"true", "1", "yes"}:
        raise ValueError("Telegram migration requires restricted user access")
    # python-dotenv accepts single-quoted values, including escaped apostrophes.
    body = "".join(
        f"{key}='" + value.replace("\\", "\\\\").replace("'", "\\'") + "'\n"
        for key, value in sorted(values.items())
    )
    destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=destination.parent, prefix=".telegram-env-", delete=False
        ) as output:
            temporary = Path(output.name)
            os.fchmod(output.fileno(), 0o600)
            output.write(body)
        os.replace(temporary, destination)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        prepare(Path(sys.argv[1]), Path(sys.argv[2]))
    except (OSError, ValueError):
        sys.exit("Telegram environment preparation failed; check source access and required settings")
