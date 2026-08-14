#!/bin/sh
# shellcheck shell=sh

set -eu

src="$1"
formatter="$2"
out="$3"

#> Copy everything except dotfiles/dot-directories (.git, .direnv, etc.)
cp -r "$src"/* .
chmod -R +w .

#? Dotfiles are excluded by the glob above, so known config files
#? are allowlisted back in explicitly, one location-variant per line.
configs="
shellcheckrc .shellcheckrc .config/shellcheckrc
treefmt.toml .treefmt.toml .config/treefmt.toml
rustfmt.toml .rustfmt.toml .config/rustfmt.toml
markdownlint.yaml .markdownlint.yaml .config/markdownlint.yaml
typos.toml .typos.toml .config/typos.toml
"

for config in $configs; do
  if [ -f "$src/$config" ]; then
    mkdir -p "$(dirname "$config")"
    cp "$src/$config" "$config"
  fi
done

"$formatter" --no-cache --fail-on-change
touch "$out"
