def prompt_by_starship [] {
    ^starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

let-env STARSHIP_SHELL = "nu"
let-env PROMPT_COMMAND = { || prompt_by_starship }
let-env PROMPT_INDICATOR = { || "" }
let-env PROMPT_INDICATOR_VI_NORMAL = { || "" }
let-env PROMPT_INDICATOR_VI_INSERT = { || ": " }
let-env PROMPT_MULTILINE_INDICATOR = { || "::: " }