import pathlib
import sys


def main() -> int:
    env_path = pathlib.Path(sys.argv[1])
    key = sys.argv[2]
    value = sys.argv[3]

    lines = []
    if env_path.exists():
        lines = env_path.read_text().splitlines()

    prefix = f"{key}="
    updated = False
    for index, line in enumerate(lines):
        if line.startswith(prefix):
            lines[index] = f"{key}={value}"
            updated = True
            break

    if not updated:
        lines.append(f"{key}={value}")

    env_path.write_text("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
