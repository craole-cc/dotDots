#!/bin/sh
# shellcheck disable=SC2034,SC1090,SC2154

#>-> Rust
if ! command -v rustc >/dev/null 2>&1; then return; fi
manage_env --var RUST_HOME --val "${DOTS_CFG:?}/rust"

#>-> Rustup
manage_env --var RUSTUP_HOME --val "${HOME:?}/.rustup"
case "${SYS_TYPE}" in
Windows) RUSTUP_CONFIG="${RUST_HOME}/rustup_win.toml" ;;
*) RUSTUP_CONFIG="${RUST_HOME}/rustup_unix.toml" ;;
esac
manage_env --var RUSTUP_CONFIG --val "${RUSTUP_CONFIG}"

#>-> Cargo
manage_env --var CARGO_HOME --val "${HOME}/.cargo"
manage_env --init --var CARGO_ENV --val "${RUST_HOME}/cargo.env"
manage_env --var CARGO_CONFIG --val "${RUST_HOME}/cargo.toml"
manage_env --var CARGO_CONFIG_USER --val "${CARGO_HOME}/config.toml"
copy_config "${CARGO_CONFIG:-}" "${CARGO_CONFIG_USER:-}"
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

#>-> Rustfmt
manage_env --var RUSTFMT_CONFIG --val "${RUST_HOME}/rustfmt.toml"
manage_env --var RUSTFMT_CONFIG_USER --val "${HOME}/.rustfmt.toml"
copy_config "${RUSTFMT_CONFIG:-}" "${RUSTFMT_CONFIG_USER:-}"

#>-> Shell Completions
case "${SHELL_TYPE}" in
bash)
  COMPLETIONS_RUSTUP="${RUST_HOME}/rustup_completions.bash"
  if [ ! -f "${COMPLETIONS_RUSTUP}" ]; then
    rustup completions bash >"${COMPLETIONS_RUSTUP}"
  fi

  COMPLETIONS_CARGO="${RUST_HOME}/cargo_completions.bash"
  if [ ! -f "${CARGO_COMPLETIONS_BASH}" ]; then
    rustup completions bash cargo >"${COMPLETIONS_CARGO}"
  fi
  ;;
zsh)
  COMPLETIONS_RUSTUP="${RUST_HOME}/rustup_completions.zsh"
  if [ ! -f "${COMPLETIONS_RUSTUP}" ]; then
    rustup completions zsh >"${COMPLETIONS_RUSTUP}"
  fi

  COMPLETIONS_CARGO="${RUST_HOME}/cargo_completions.zsh"
  if [ ! -f "${CARGO_COMPLETIONS_ZSH}" ]; then
    rustup completions zsh cargo >"${COMPLETIONS_CARGO}"
  fi
  ;;
*) ;;
esac
manage_env --init --var COMPLETIONS_RUSTUP --val "${COMPLETIONS_RUSTUP}"
manage_env --init --var COMPLETIONS_CARGO --val "${COMPLETIONS_CARGO}"
