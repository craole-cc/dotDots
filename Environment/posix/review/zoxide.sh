#! /bin/sh

#==================================================
# NU
#==================================================

# _________________________________ DOCUMENTATION<|
# https://github.com/nushell/nushell/
# _________________________________________ LOCAL<|

#> Install <#
weHave zoxide || cargo binstall zoxide --locked

#> Verify Instalation <#
weHave zoxide || return
"$NeedForSpeed" || weHave --report version zoxide >>"$DOTS_loaded_apps"

# _____________________________________ Shortcuts<|

Zoxide() {
  if weHave zoxide; then
    export _ZO_DATA_DIR="${dotCLI:?}/zoxide"
    # export _ZO_ECHO='1'
    export _ZO_RESOLVE_SYMLINKS='1'
    # shellcheck disable=SC3046
    case "${sys_SHELL:-?}" in
    GitBASH | baSHell)
      skipPOSIX eval "$(zoxide init bash)"
      # eval "$(zoxide init posix --hook prompt)"
      ;;
    zSHell) eval "$(zoxide init zsh)" ;;
    fiSHell) zoxide init fish | source ;;
    *) ;;
    esac

  else
    printf """
  zoxide is not installed.
  :: Install using ::
  cargo install zoxide --locked
  """
    return 1
  fi
}
