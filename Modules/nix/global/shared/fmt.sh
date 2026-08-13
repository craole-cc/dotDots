#!/bin/sh
# shellcheck enable=all

set -eu

src="$1"
formatter_exe="$2"

cp -r "$src"/* .
chmod -R +w .

configs="
shellcheckrc .shellcheckrc
treefmt.toml .treefmt.toml
rustfmt.toml .rustfmt.toml
markdownlint.yaml .markdownlint.yaml
typos.toml .typos.toml
.config/treefmt.toml .config/rustfmt.toml
.config/markdownlint.yaml .config/typos.toml
"

for config in $configs; do
  if [ -f "$src/$config" ]; then
    mkdir -p "$(dirname "$config")"
    cp "$src/$config" "$config"
  fi
done

"$formatter_exe" --no-cache --fail-on-change
touch "$out"
