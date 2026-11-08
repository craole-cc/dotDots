---
name: sh-utils
description: Prefer modern CLI utilities (fd, rg, sd, bat, eza, dust, procs,
  tokei) over find, grep, sed, cat, ls, du and ps. Use whenever searching,
  listing, replacing text or inspecting files from the shell.
---

# Modern Shell Utilities

Prefer the modern tool when it is installed. If it is missing, fall back to
the classic equivalent. Do **not** install anything to make a command work.

## Quick reference

| Task            | Modern                   | Legacy                |
| --------------- | ------------------------ | --------------------- |
| Find files      | `fd PATTERN [PATH]`      | `find`                |
| Search contents | `rg PATTERN [PATH]`      | `grep -r`             |
| Replace text    | `sd 'from' 'to' FILE...` | `sed`                 |
| Read a file     | `bat FILE`               | `cat` / `sed -n`      |
| List files      | `eza -la`                | `ls -la`              |
| Disk usage      | `dust -d 2`              | `du`                  |
| Processes       | `procs NAME`             | `ps aux \| grep NAME` |
| Code size       | `tokei`                  | `wc -l` / `cloc`      |

## Flags

| Tool    | Flag                  | Description                        |
| ------- | --------------------- | ---------------------------------- |
| `fd`    | `-e nix`              | Filter by extension                |
|         | `-t f`                | Files only                         |
|         | `-H`                  | Include hidden                     |
|         | `-I`                  | Include gitignored                 |
|         | `-x CMD`              | Execute command per result         |
| `rg`    | `-F`                  | Literal (non-regex)                |
|         | `-i`                  | Case-insensitive                   |
|         | `-g '*.nix'`          | Glob filter                        |
|         | `-t nix`              | File type                          |
|         | `-l`                  | File names only                    |
|         | `-C 2`                | Context lines                      |
|         | `-uu`                 | Include hidden + ignored           |
|         | `--files`             | List files (no search)             |
| `sd`    | `-p`                  | Preview (don't write)              |
|         | `-F`                  | Literal (non-regex)                |
|         | `$1`, `${1}`, `$name` | Capture groups                     |
| `bat`   | `--plain`             | No decorations                     |
|         | `--paging=never`      | No pager                           |
|         | `-r START:END`        | Line range                         |
|         | `-n`                  | Line numbers, no other decorations |
| `eza`   | `--tree --depth 2`    | Tree view                          |
| `dust`  | `-d N`                | Depth limit                        |
|         | `-b`                  | Suppress percent bars              |
| `procs` | `-n`                  | Top N                              |
|         | `-s cpu`              | Sort by CPU                        |

## Notes

- **Hidden & ignored files.** `fd` and `rg` skip them by default. If a
  search finds nothing you expected, retry with `-H -I` (fd) or `-uu` (rg)
  before concluding a file does not exist.
- **Portability.** Scripts, CI steps, Nix derivations, and anything committed
  for others to run should stick to POSIX tools unless the project already
  depends on the modern ones.
- **Do not parse decorated output.** `bat`, `eza`, and `lsd` add colors,
  icons, and alignment for humans. Use `--plain` / `--style=plain` or the
  classic tool when a script needs to read the output.
- **sd** edits in place by default. Always use `-p` first to preview.
  Reads stdin when no file is given.
- **bat**: plain `cat` is still correct for piping or concatenation.
- **eza**: `lsd` is a near drop-in equivalent.
