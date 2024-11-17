#!/bin/sh
# shellcheck disable=SC2034,SC1090,SC2154

#==================================================
# RUSTUP
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|
# --> Hatch
HATCH_CONFIG="$DOTS_CLI/python/hatch.toml"
# _HATCH_COMPLETE=bash_source hatch > "$DOTS_CLI/bash/resources/hatch-complete.bash"

# HATCH_DATA_DIR


# _________________________________________ TOOLS<|

#> Load Config
[ -f "$CARGO_ENV" ] && . "$CARGO_ENV"

#> Install Rust if missing
command -v rustc >/dev/null 2>&1 || install_rust


# _________________________________________ ALIAS<|
alias P='python'
alias Pi='pipx'
alias H='hatch'