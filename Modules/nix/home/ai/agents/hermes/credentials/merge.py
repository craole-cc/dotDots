"""Merge ordered runtime dotenv sources without evaluating their contents in Nix."""

import glob
import os
from pathlib import Path
import stat
import sys
import tempfile

from dotenv import dotenv_values


def merge(destination: Path, sources: list[str]) -> None:
    values = {}
    for source in sources:
        paths = sorted(glob.glob(source)) if glob.has_magic(source) else [source]
        for name in paths:
            path = Path(name)
            if not path.exists() and not path.is_symlink():
                continue
            metadata = path.lstat()
            if (
                not stat.S_ISREG(metadata.st_mode)
                or metadata.st_uid != os.getuid()
                or metadata.st_mode & 0o077
                or path.resolve() == destination.resolve()
            ):
                raise ValueError("Credential sources must be private, user-owned regular files")
            values.update({
                key: value
                for key, value in dotenv_values(path, interpolate=False).items()
                if value is not None
            })
    body = "".join(
        f"{key}='" + value.replace("\\", "\\\\").replace("'", "\\'") + "'\n"
        for key, value in sorted(values.items())
    )
    destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=destination.parent, prefix=".credentials-", delete=False
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
        merge(Path(sys.argv[1]), sys.argv[2:])
    except (OSError, ValueError):
        sys.exit("Hermes credential preparation failed; check source access and permissions")
