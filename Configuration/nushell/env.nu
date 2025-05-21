# Nushell Environment Config File

# Define the DOTS environment variable if not already set
$env.DOTS = ($env | default $"($env.HOME)/.dots" DOTS)

# Environment conversions for PATH variables
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

# Set up library and plugin directories
$env.NU_LIB_DIRS = [
    ($nu.config-path | path dirname | path join 'libraries')
    ($env.DOTS | path join 'Configuration/nushell/libraries')
]

$env.NU_PLUGIN_DIRS = [
    ($nu.config-path | path dirname | path join 'plugins')
    ($env.DOTS | path join 'Configuration/nushell/plugins')
]

# Common environment variables
$env.SHELL = 'nu'
$env.EDITOR = 'helix'
$env.FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
$env.GREP_OPTIONS = '--color=auto'
$env.PF_INFO = 'ascii title os host kernel uptime memory shell editor'

# Configure starship prompt
def prompt_by_starship [] {
    ^starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

$env.STARSHIP_SHELL = "nu"
$env.STARSHIP_CONFIG = ($env.DOTS | path join "Configuration/starship/config.toml")
$env.PROMPT_COMMAND = { || prompt_by_starship }
$env.PROMPT_INDICATOR = { || "" }
$env.PROMPT_INDICATOR_VI_NORMAL = { || "" }
$env.PROMPT_INDICATOR_VI_INSERT = { || ": " }
$env.PROMPT_MULTILINE_INDICATOR = { || "::: " }

# Add dotfiles bin directories to PATH
$env.PATH = ($env.PATH | prepend [
    ($env.DOTS | path join "Bin")
    ($env.DOTS | path join "Bin/nushell")
])

# Load custom modules if they exist
def load_custom_modules [] {
    let modules_dir = ($env.DOTS | path join "Configuration/nushell/modules")
    if ($modules_dir | path exists) {
        ls $modules_dir |
            where name =~ '\.nu$' |
            each { |module|
                print $"Loading module: ($module.name)"
                source $module.name
            }
    }
}

# Run the modules loader
load_custom_modules
