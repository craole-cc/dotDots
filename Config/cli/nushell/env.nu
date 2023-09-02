# Nushell Environment Config File
# version = 0.78.0

# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

$env.NU_LIB_DIRS = [($nu.config-path | path dirname | path join 'libraries')]
$env.NU_PLUGIN_DIRS = [ ($nu.config-path | path dirname | path join 'plugins')]

$env.SHELL = 'nu'
$env.EDITOR = 'helix'
$env.FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
$env.GPG_TTY = (tty | str trim)
$env.GREP_OPTIONS = '--color=auto'
$env.PF_INFO = 'ascii title os host kernel uptime memory shell editor'

#/> PROMPT                                                         <\#
def prompt_by_starship [] {
    ^starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

$env.STARSHIP_SHELL = "nu"
$env.PROMPT_COMMAND = { || prompt_by_starship }
$env.PROMPT_INDICATOR = { || "" }
$env.PROMPT_INDICATOR_VI_NORMAL = { || "" }
$env.PROMPT_INDICATOR_VI_INSERT = { || ": " }
$env.PROMPT_MULTILINE_INDICATOR = { || "::: " }