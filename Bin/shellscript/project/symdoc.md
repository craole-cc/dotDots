# symdoc

A POSIX shell script that creates a documentation mirror by symlinking all `.md` files from a library directory.

## Usage

```sh
symdoc [OPTIONS]
```

## Options

- `-l, --lib-dir DIR` - Library directory (default: auto-detect)
- `-d, --doc-dir DIR` - Documentation directory (default: $PROJECT_ROOT/Documentation)
- `-v, --verbose` - Show detailed output
- `-n, --dry-run` - Preview changes without making them
- `-c, --clean` - Remove broken symlinks first
- `-q, --quiet` - No output (check exit code)

## Features

- Auto-discovers project root (`.git`, `flake.nix`, `Cargo.toml`)
- Preserves directory structure
- Idempotent (safe to run multiple times)
- Generates automatic index
