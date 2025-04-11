{ pkgs, ... }:
with pkgs;
[
  # |Formatters
  # alejandra
  # biome
  deadnix
  deno
  markdownlint-cli2
  mdsh
  nodePackages.prettier
  ruff
  shellcheck
  shfmt
  taplo
  taplo
  treefmt
  yamlfmt
]
