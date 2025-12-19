{pkgs, ...}:
with pkgs; [
  # Core tools
  bat
  fd
  gitui
  gnused
  jq
  nil
  nixd
  onefetch
  undollar

  # Rust toolchain (for building dots-cli)
  rustc
  cargo
  rust-analyzer
  rustfmt

  # Clipboard dependencies
  xclip
  wl-clipboard
  xsel

  # Formatters
  alejandra
  markdownlint-cli2
  nixfmt
  shellcheck
  shfmt
  taplo
  treefmt
  yamlfmt
]
