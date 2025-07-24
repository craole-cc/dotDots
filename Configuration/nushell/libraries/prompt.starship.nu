# ===========================================================================
# Prompt Configuration
# prompt.nu
# ===========================================================================

# Starship prompt
if (which starship | is-not-empty) {
    $env.PROMPT_MULTILINE_INDICATOR = (^starship prompt --continuation)
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_COMMAND = { ||
        let exit_code = (try { $env.LAST_EXIT_CODE } catch { 0 })
        ^starship prompt $"--cmd-duration=($env.CMD_DURATION_MS)" $"--status=($exit_code)"
    }
    $env.PROMPT_COMMAND_RIGHT = { ||
        ^starship prompt --right
    }
}

# def prompt_by_starship [] {
#     ^starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
# }

# let-env STARSHIP_SHELL = "nu"
# let-env PROMPT_COMMAND = { || prompt_by_starship }
# let-env PROMPT_INDICATOR = { || "" }
# let-env PROMPT_INDICATOR_VI_NORMAL = { || "" }
# let-env PROMPT_INDICATOR_VI_INSERT = { || ": " }
# let-env PROMPT_MULTILINE_INDICATOR = { || "::: " }
