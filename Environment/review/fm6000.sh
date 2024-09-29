#! /bin/sh

#==================================================
#
# FETCH-MASTER 6000
# CLI/bin/environment/app/fm6000.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# --> https://github.com/anhsirk0/fetch-master-6000

# _________________________________________ LOCAL<|

fm6kDIR="${DOTS_DOWN:?}/fetch-master-6000"
fm6kSRC="${fm6kDIR:?}/fm6000.pl"
fm6kLNK="${DOTS_BIN_IMPORT:?}/fm6000"

if [ -f "$fm6kSRC" ]; then
  #> Establish Link in BIN <#
  ln \
    --symbolic \
    --force \
    "$fm6kSRC" \
    "$fm6kLNK"

else
  echo "$fm6kSRC" not found
fi

#> Verify Instalation <#
# weHave fm6000 || return
# "$NeedForSpeed" || weHave --report version fm6k >>"$DOTS_loaded_apps"
# fm6000="$DOTS_DOWN/fetch-master-6000/fm6000.pl"
# fm6000="$XDG_CONFIG_HOME/fetch-master-6000/fm6000.pl"

# ________________________________________ EXPORT<|

# ______________________________________ FUNCTION<|

# --> Edit Config
cfFM() {
  $1 "$fm6kLNK"
}

# --> Edit Config
case $sys_TYPE in
Windows)
  fm6k() {
    perl "$fm6kLNK" \
      --random \
      --os "$sys_TYPE" \
      --de "$sys_ARCH" \
      --shell "${sys_SHELL:-?}" \
      --package "${pacCount:?}" \
      --uptime "$(sysUptime)" \
      --color random
  }
  ;;
*)
  fm6k() {
    perl "$fm6kLNK" \
      --random \
      --os "$sys_TYPE" \
      --de "$sys_ARCH" \
      --shell "${sys_SHELL:-?}" \
      --color random
  }
  ;;
esac

fm6kH() {
  perl "$fm6kLNK" --help
}

# fm6k() {
#   fm6000 \
#     --random \
#     --os Arch \
#     --de Qtile \
#     --not_de \
#     --color random
# }

# _________________________________________ ALIAS<|

# __________________________________________ EXEC<|

# fm6k
