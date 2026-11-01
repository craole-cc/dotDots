#!/usr/bin/env python3
"""Split the monolithic alias/source Nix file into modules.

usage: split_sources.py INPUT.nix OUTDIR [--path-depth N]

Produces:
  OUTDIR/default.nix   merges every group (throws on duplicate source names)
  OUTDIR/helpers.nix   mkAlias, mkLayeredAlias, mkAliasFamily, mergeDisjoint, mkSource
  OUTDIR/<group>.nix   one file per domain group

--path-depth N prepends N extra "../" to relative paths such as
../patches/... and ../../../posix/..., needed because the entries now live
one directory deeper (default 1; use 0 if OUTDIR sits where INPUT did).
"""

import re
import sys
from pathlib import Path

GROUPS = {
    "core": "coreutils diffutils findutils gawk gnugrep gnupatch gnused moreutils file tree".split(),
    "files": "bat dust eza fd fzf lsd yazi".split(),
    "text": "jq jaq yq-go ripgrep sd glow".split(),
    "shells": "bash dash gum gh curl rust-script".split(),
    "version-control": "git git-filter-repo gitui".split(),
    "system": "nh procps systemd util-linux iproute2".split(),
    "formatters": "alejandra biome dprint treefmt".split(),
    "archives": "ouch".split(),
    "ai": "ollama ollama-cpu llmhop".split(),
    "media": "cmus kew mpv".split(),
    "editors": "vscode-fhs vscode-insiders".split(),
    "communication": "khal vdirsyncer thunderbird python3".split(),
    "desktop-cli": "dbus glib libnotify wl-clipboard xdg-utils".split(),
    "desktop-ui": (
        "dms-shell dux-calendar ghostty kitty foot warp-terminal nemo "
        "hyprpaper quickshell swaybg variety"
    ).split(),
}

# let-bound names from the original header that entries may use
EXTRA_INHERITS = {
    "readFile": "inherit (_.filesystem.access) readFile;",
    "replaceStrings": "inherit (_.strings.transformation) replaceStrings;",
    "mapAttrsToList": "inherit (_.attrsets.transformation) mapAttrsToList;",
    "optionalAttrs": "inherit (_.attrsets.construction) optionalAttrs;",
    "concat": "inherit (_.strings.construction) concat;",
    "filter": "inherit (_.lists.transformation) filter;",
    "concatMap": "inherit (_.lists.aggregation) concatMap;",
}
HELPERS = ["mkAlias", "mkLayeredAlias", "mkAliasFamily", "mergeDisjoint", "mkSource"]
START = re.compile(r"^  ([A-Za-z0-9_-]+) = ")


def fix_paths(text, depth):
    if not depth:
        return text
    return re.sub(r"(?<![\w./])((?:\.\./)+)", "../" * depth + r"\1", text)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    depth = 1
    if "--path-depth" in sys.argv:
        depth = int(sys.argv[sys.argv.index("--path-depth") + 1])
        args = [a for a in args if a != str(depth)]
    src, out = Path(args[0]), Path(args[1])
    lines = src.read_text().splitlines()

    # header = everything before the line that opens the final attrset
    body_start = next(i for i, l in enumerate(lines) if l == "in {")
    header = lines[:body_start]
    body = lines[body_start + 1 : -1]  # drop trailing "}"
    assert lines[-1].strip() == "}", "expected file to end with a closing brace"

    # split body into entries
    entries, cur_name, cur = {}, None, []
    for l in body:
        m = START.match(l)
        if m:
            if cur_name:
                entries[cur_name] = cur
            cur_name, cur = m.group(1), [l]
        elif cur_name:
            cur.append(l)
    entries[cur_name] = cur

    out.mkdir(parents=True, exist_ok=True)

    # helpers.nix: the original let-block, re-exported
    (out / "helpers.nix").write_text(
        "\n".join(header) + "\nin {\n  inherit " + " ".join(HELPERS) + ";\n}\n"
    )

    assigned = {n for names in GROUPS.values() for n in names}
    groups = {g: [n for n in names if n in entries] for g, names in GROUPS.items()}
    leftover = [n for n in entries if n not in assigned]
    if leftover:
        groups["misc"] = leftover
        print("unassigned entries placed in misc.nix:", ", ".join(leftover))
    missing = [n for n in assigned if n not in entries]
    if missing:
        print("listed in GROUPS but not found:", ", ".join(missing))

    for group, names in groups.items():
        if not names:
            continue
        text = "\n".join(
            fix_paths("\n".join(strip_trailing_blank(entries[n])), depth) for n in names
        )
        used = [h for h in HELPERS if re.search(rf"\b{h}\b", text)]
        inh = [f"  inherit (h) {' '.join(used)};"] if used else []
        for name, line in EXTRA_INHERITS.items():
            if re.search(rf"\b{name}\b", text):
                inh.append("  " + line)
        pre = "{_, h, ...}: let\n" + "\n".join(inh) + "\nin {\n"
        (out / f"{group}.nix").write_text(pre + text + "\n}\n")

    files = " ".join(f"      ./{g}.nix\n" for g, n in groups.items() if n)
    (out / "default.nix").write_text(
        "{_, ...}: let\n"
        "  h = import ./helpers.nix {inherit _;};\n"
        "  load = file: import file {inherit _ h;};\n"
        "in\n"
        "  h.mergeDisjoint (map load [\n"
        + "".join(f"    ./{g}.nix\n" for g, n in groups.items() if n)
        + "  ])\n"
    )
    print(f"wrote {sum(1 for n in groups.values() if n)} group files to {out}")
    print("next: run `alejandra .` and `nix flake check` / your eval")


def strip_trailing_blank(block):
    while block and not block[-1].strip():
        block = block[:-1]
    return block + [""]


if __name__ == "__main__":
    main()
