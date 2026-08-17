#!/bin/sh
# shellcheck shell=sh

set -eu

src="$1"
formatter="$2"
out="$3"

#> Copy source tree.
cp -r "$src"/* .

#> Dotfiles are excluded by the glob above, so known config files
#> are allowlisted back in explicitly.
cp "$src/.treefmt.toml" .treefmt.toml

configs="
shellcheckrc .shellcheckrc .config/shellcheckrc
tombi.toml .tombi.toml .config/tombi.toml
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

#> Nix store sources are read-only; formatters need a writable work tree.
chmod -R u+w .

"$formatter" \
  --config-file .treefmt.toml \
  --no-cache \
  --fail-on-change

touch "$out"
