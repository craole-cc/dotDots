#!/bin/sh
# shellcheck disable=SC2034,SC1090,SC2154

#==================================================
# RUSTUP
#==================================================

# _________________________________ DOCUMENTATION<|
weHave rustc || return

# _________________________________________ LOCAL<|

# --> Rustup
RUSTUP_HOME="$HOME/.rustup"
# RUSTUP_CONFIG="$DOTS_TOOL/utilities/rustup/settings.toml"
RUSTUP_CONFIG="$RUSTUP_HOME/settings.toml"
RUSTUP_BASH_COMPLETION="$BASH_COMPLETION/completions/rustup"

# --> Cargo
CARGO_HOME="$HOME/.cargo"
CARGO_CONFIG="$CARGO_HOME/.crates.toml"
CARGO_ENV="$CARGO_HOME/env"
#CARGO_ENV="$DOTS_TOOL/utilities/rustup/env"

# _________________________________________ TOOLS<|

#> Load Config
[ -f "$CARGO_ENV" ] && . "$CARGO_ENV"

#> Install Rust if missing
weHave rustc || install_rust

#> Completion
case "$sys_INFO" in
baSHell) rustup completions bash ;;
zSHell) rustup completions zsh ;;
fiSHell) rustup completions fish ;;
pwsh) rustup completions powershell ;;
esac

# _________________________________________ ALIAS<|
alias C='cargo'
alias Cin='install_via_cargo'
alias Cun='cargoUninstall'

alias Cn='cargo new'
alias Ci='cargo init'
alias Cb='cargo build'
alias Cbr='cargo build --release'
alias Cr='cargo run --quiet --'
alias Cw='cargo watch \
--quiet \
--clear \
--exec'
alias Cwrh='cw "run --quiet -- --help"'
