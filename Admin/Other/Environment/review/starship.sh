#! /bin/sh

#==================================================
#
# STARSHIP
# CLI/bin/environment/app/starship.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|

unset STARSHIP_CONFIG STARSHIP_CACHE
STARSHIP_CONFIG="${DOTS_CLI}/starship/config.toml"
STARSHIP_CACHE="${CACHE_HOME}/starship"

#> Verify Instalation <#
# weHave starship || return
# "$NeedForSpeed" || weHave --report version starship >>"$DOTS_loaded_apps"

# --> Edit Config
cfStar() {
    $1 "$STARSHIP_CONFIG"
}
