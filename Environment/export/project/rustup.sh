#!/bin/sh
# shellcheck disable=SC2034,SC1090,SC2154

#==================================================
# RUSTUP
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|
# --> Rustup
RUSTUP_HOME="$HOME/.rustup"
# RUSTUP_CONFIG="$DOTS_TOOL/utilities/rustup/settings.toml"
RUSTUP_CONFIG="$RUSTUP_HOME/settings.toml"
RUSTUP_BASH_COMPLETION="$BDOTDIR/scripts/rustup"

# --> Cargo
CARGO_HOME="$HOME/.cargo"
CARGO_CONFIG="$CARGO_HOME/.crates.toml"
CARGO_ENV="$CARGO_HOME/env"
#CARGO_ENV="$DOTS_TOOL/utilities/rustup/env"

# _________________________________________ TOOLS<|

#@ Load Config
[ -f "$CARGO_ENV" ] && . "$CARGO_ENV"

#@ Install Rust if missing
command -v rustc >/dev/null 2>&1 || install_rust

# #@ Enable completions
# case "$sys_INFO" in
# pwsh) rustup completions powershell ;;
# zSHell) rustup completions zsh ;;
# fiSHell) rustup completions fish ;;
# baSHell | *sh | *SH) rustup completions bash >"$RUSTUP_BASH_COMPLETION" ;;
# esac

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
