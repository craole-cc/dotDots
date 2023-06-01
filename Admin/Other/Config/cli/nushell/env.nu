# Nushell Environment Config File
# version = 0.78.0

let-env ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) | path expand -n }
    to_string: { |v| $v | path expand -n | str join (char esep) }
  }
}

let-env NU_LIB_DIRS = [($nu.config-path | path dirname | path join 'libraries')]
let-env NU_PLUGIN_DIRS = [ ($nu.config-path | path dirname | path join 'plugins')]

let-env SHELL = 'nu'
let-env EDITOR = 'helix'
let-env FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
let-env GPG_TTY = (tty | str trim)
let-env GREP_OPTIONS = '--color=auto'
let-env PF_INFO = 'ascii title os host kernel uptime memory shell editor'

#/> PROMPT                                                         <\#
def prompt_by_starship [] {
    ^starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

let-env STARSHIP_SHELL = "nu"
let-env PROMPT_COMMAND = { || prompt_by_starship }
let-env PROMPT_INDICATOR = { || "" }
let-env PROMPT_INDICATOR_VI_NORMAL = { || "" }
let-env PROMPT_INDICATOR_VI_INSERT = { || ": " }
let-env PROMPT_MULTILINE_INDICATOR = { || "::: " }