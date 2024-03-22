#!/bin/sh
# shellcheck disable=SC2034,SC1090,SC2154

#==================================================
# RUSTUP
#==================================================

# _________________________________ DOCUMENTATION<|

command -v rustc >/dev/null 2>&1 || return

# _________________________________________ LOCAL<|

# --> Rustup
RUST_HOME="$DOTS_CLI/rust"
RUSTUP_HOME="$HOME/.rustup"
RUSTUP_BASH_COMPLETION="$BDOTDIR/functions/rustup"
case "$sys_INFO" in
*Windows*) RUSTUP_CONFIG="$RUST_HOME/rustup_win.toml" ;;
*) RUSTUP_CONFIG="$RUST_HOME/rustup_unix.toml" ;;
esac

# --> Cargo
CARGO_HOME="$HOME/.cargo"
CARGO_CONFIG="$RUST_HOME/cargo.toml"
CARGO_ENV="$RUST_HOME/cargo.env"
RUSTFMT_CONFIG="$RUST_HOME/rustfmt.toml"

# _________________________________________ TOOLS<|

#> Load Config
[ -f "$CARGO_ENV" ] && . "$CARGO_ENV"

[ -d "$CARGO_HOME" ] && [ -f "$CARGO_CONFIG" ] && {
  ln --symbolic --force "$CARGO_CONFIG" "$CARGO_HOME/config.toml"
}

[ -f "$RUSTFMT_CONFIG" ] && {
  [ -d "$CONFIG_HOME/rustfmt" ] || mkdir --parents "$DATA_HOME/rustfmt"
  ln --symbolic --force "$RUSTFMT_CONFIG" "$DATA_HOME/rustfmt"
}

# _________________________________________ ALIAS<|
alias C='cargo'
alias Cin='install_via_cargo'
alias Cun='cargoUninstall'

alias Cn='cargo new'
alias Ci='cargo init'
alias Cb='cargo build'
alias Cbr='cargo build --release'
alias Cr='cargo run --quiet --'
alias Cw='cargo watch --quiet --clear --exec'
alias Cwrh='cw "run --quiet -- --help"'
