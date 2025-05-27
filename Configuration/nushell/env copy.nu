# ===========================================================================
# DOTS Nushell Environment Configuration
# $DOTS/Configuration/nushell/env.nu
# ===========================================================================

# Set up plugin directory
let plugin_dir = ($env.DOTS | path join "Bin" "nushell")
if ($plugin_dir | path exists) {
    $env.NU_PLUGIN_DIRS = [$plugin_dir]
}

# Initialize Starship prompt
if (which starship | is-not-empty) {
    $env.STARSHIP_SHELL = "nu"
    $env.STARSHIP_SESSION_KEY = (random chars -l 16)
    $env.PROMPT_MULTILINE_INDICATOR = (^starship prompt --continuation)
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_COMMAND = { ||
        let job_id = (try { $env.LAST_EXIT_CODE } catch { 0 })
        ^starship prompt $"--cmd-duration=($env.CMD_DURATION_MS)" $"--status=($job_id)"
    }
    $env.PROMPT_COMMAND_RIGHT = { ||
        ^starship prompt --right
    }
}
