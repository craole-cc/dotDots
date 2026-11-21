"""Load private dotenv files into an agent's process environment at launch."""

import glob
import os
import sys
from pathlib import Path

from dotenv import dotenv_values


def load_environment(sources, inherited):
    environment = dict(inherited)
    for source in sources:
        for filename in sorted(glob.glob(os.path.expanduser(source))):
            if not Path(filename).is_file():
                continue
            # Disable interpolation so credentials containing ${...} stay literal.
            values = dotenv_values(filename, interpolate=False)
            environment.update(
                (key, value) for key, value in values.items() if value is not None
            )
    return environment


def main():
    separator = sys.argv.index("--")
    sources = sys.argv[1:separator]
    command = sys.argv[separator + 1:]
    os.execve(command[0], command, load_environment(sources, os.environ))


if __name__ == "__main__":
    main()
