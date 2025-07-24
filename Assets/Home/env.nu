# ===========================================================================
# DOTS Bootstrap for Nushell
# Finds and sets the DOTS and DOTS_RC environment variables
# $nu.env-path | path dirname
# ===========================================================================

let parents = [
  "D:/Projects/GitHub/CC"
  "D:/Configuration"
  "D:/Dotfiles"
  $env.USERPROFILE
  # $env.HOME
]

let targets = [
  ".dots"
  "dotDots"
  "dots"
  "dotfiles"
  "global"
  "config"
  "common"
]

for parent in $parents {
  if ($parent | path exists) {
    for target in $targets {
      let dots = $parent | path join $target
      let dots_rc = $dots | path join ".dotsrc"
      let dots_bin = $dots | path join "Bin"
      let dots_bin_nu = $dots_bin | path join "nushell"
      let dots_cfg = $dots | path join "Configuration"
      let dots_cfg_nu = $dots_cfg | path join "nushell"
      let dots_mod = $dots | path join "Modules"

      if ($dots_rc | path exists) {
        $env.DOTS = $dots
        $env.DOTS_RC = $dots_rc
        $env.DOTS_BIN = $dots_bin
        $env.DOTS_BIN_NU = $dots_bin_nu
        $env.DOTS_CFG = $dots_cfg
        $env.DOTS_CFG_NU = $dots_cfg_nu
        $env.DOTS_MOD = $dots_mod

        break
      }
    }
    if "DOTS" in $env { break }
  }
}
