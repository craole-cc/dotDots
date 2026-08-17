#!/bin/sh

set -eu

src="$1"
formatter="$2"
out="$3"

cp -r "$src"/* .
chmod -R +w .

# Canonical treefmt config
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

"$formatter" \
  --config-file .treefmt.toml \
  --no-cache \
  --fail-on-change

touch "$out"
