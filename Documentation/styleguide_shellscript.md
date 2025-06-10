# Shell Scripting Style Guide

> **Author:** Craig Cole
> **Version:** 1.0
> **License:** MIT
> **Source:** [dotDots](https://github.com/craole-cc/dotDots.git)

## Overview

This style guide defines the conventions for writing shell scripts in this codebase. It is based on personal best practices, ShellCheck recommendations (`# shellcheck enable=all`), and a focus on maintainability, clarity, and POSIX compliance.

## 1. Interpreter and ShellCheck

- Always start scripts with `#!/bin/sh` for POSIX compliance, or `#!/bin/bash` if Bash features are required.
- Always include `# shellcheck enable=all` at the top of each script.
- Use `# shellcheck disable=SC####` only if absolutely neceessary
- Run ShellCheck on all scripts before committing.

## 2. Script Structure

- **Sub-functions:**
  Every script must define the following functions:
  - `main`
  - `cleanup`
  - `set_defaults`
  - `set_modes`
  - `parse_arguments`
  - `establish_environment`
  - `execute_process`
- **Function Order:**
  Place `main` at the top, followed by `cleanup`, then the rest in logical order.
- **Execution:**
  End every script with `main "$@"`.
- **Trap:**
  `main` must always set a `trap` to call `cleanup` on `EXIT HUP INT TERM`.
- **Cleanup:**
  `cleanup` is always called before defining local variables in `set_defaults`.

## 3. Argument Parsing

- Use a `while` loop with a `case` statement for parsing arguments.
- Always shift **once** at the end of each `case` iteration.
- Use descriptive option names and support both short and long forms.
- For options requiring arguments, check if the next argument exists.

## 4. Code Style

- **Output:**
  Always use `printf '%s\n'` over `echo`.
- **String Comparison:**
  Use `case` for all string comparisons, not `if`.
- **Variable References:**
  Always use braces: `${var}` (even when not required).
- **Quoting:**
  Always quote variable expansions: `"${var}"`
- **Exhaustiveness:**
  Ensure `case` statements are exhaustive with `*) ... ;;` as default, even for error handling.
- **Tests:**
  Use `[ ... ]` for POSIX scripts. Use `[[ ... ]]` only in Bash/Ksh scripts.
- **Indentation:**
  Use 2 spaces per indentation level.
- **Comments:**
  - Use `#{ ... }` for structural or section comments.
  - Use `#|-> ...` for metadata or grouped variable comments.
  - Use `#? ...` for notes, explanations, or TODOs.
  - Use `#DOC` for function documentation blocks.

## 5. Variable and Function Naming

- Use descriptive, lowercase names with underscores.
- Prefix internal/helper functions with the script or context name.
- All variables must be initialized before use.
- Don't use `local` for variables in POSIX sh (in shells that support it).

## 6. Defaults and Environment

- All defaults are set in `set_defaults`.
- Always reset the environment in `set_defaults` by calling `cleanup`.
- Use environment variables for configuration, but always provide sensible fallbacks.

## 7. Error Handling

- Use `set -e` (strict mode) to encourage clean code.
- Always check for required arguments and print errors to `stderr`.
- Use clear, tagged error messages (e.g., `pout-tagged --tag "[ERROR]" --ctx "${fn_name}" --msg "..."`).
- Exit with non-zero status on error.

## 8. Documentation

- Every function must have a `#DOC` block describing its purpose, usage, arguments, and return values.
- Provide a usage/help function for every script.

## 9. Miscellaneous

- Always clean up temporary variables and files in `cleanup`.
- Use `trap` to ensure cleanup on exit or interruption.
- Avoid `eval` unless absolutely necessary.
- Do not hardcode sensitive information.

## 10. Example Script Skeleton

```sh
#!/bin/sh
# shellcheck enable=all

#DOC Demonstrates a POSIX-compliant shell script matching the style guide.
#DOC
#DOC Usage: ${0##*/} [options] [arguments]
#DOC
#DOC Options:
#DOC   -h, --help      Print this help message
#DOC   -v, --version   Print the script version

main() {
  trap 'cleanup' EXIT HUP INT TERM
  set_defaults
  set_modes
  parse_arguments "$@"
  establish_environment
  execute_process
}

cleanup() {
  #{ Capture the exit code }
  exit_code=$?

  #{ Remove temporary files }
  rm -f "${tmp_dir:-}"

  #{ Unset all script variables }
  unset delimiter verbosity
  unset var1 var2 var3 tmp_dir tmp_file

  #{ Exit with original exit code }
  exit "${exit_code:-}"
}

set_defaults() {
  #|-> Environmental variables
  : "${DELIMITER:="$(printf '\037')"}"
  : "${VERBOSITY:=3}"

  #|-> Local/Default variales
  cleanup
  delimiter="${DELIMITER}"
  verbosity="${VERBOSITY}"
  var1="default"
  var2=""

  #|-> Modes
  set_mode strict
  set_mode "${verbosity}"
}

set_mode() {
  while [ "$#" -ge 1 ]; do
    case "$1" in
      -s | *strict) set -e  ;;
      -q | *quiet) verbosity=0;;
      -e | *error) verbosity=1;;
      -i | *info) verbosity=3;;
      -d | *debug) verbosity=4;;
      -t | *trace | -v | *verbose) verbosity=5;;
      *)
        pout-tagged --ctx "${fn_name}" --tag "[ERROR]" \
          "Unknown mode: $1";
        exit 1
        ;;
    esac
    shift
  done
}

parse_arguments() {
  while [ "$#" -ge 1 ]; do
    case "$1" in
      -h | --help) show_help; exit 0 ;;
      -v | --version) show_version; exit 0 ;;
      # ... more options ...
      -a | --arg)
        if [ -n "${2:-}" ]; then
          args="${args:+${args}${delimiter}}$2"
          shift
        else
          pout-tagged --ctx "${fn_name}" --tag "[ERROR]" \
            "Missing argument for $1"
          exit 1
        fi
        ;;
      --)
        #? Remaining arguments are meant for the editor
        shift
        while [ "$#" -ge 1 ]; do
          trailing_args="${trailing_args:+${trailing_args}${delimiter}}$1"
          shift
        done
        break
        ;;
      *)
        args="${args:+${args}${delimiter}}$1"
        ;;
    esac
    shift
  done
}

execute_process() {
  #{ Validate required arguments }
  if [ -z "${args:-}" ]; then
    pout-tagged --ctx "${fn_name}" --tag "[ERROR]" \
      "Missing required argument"
    exit 1
  fi
}
# ... other functions ...

main "$@"
```

## 11. References

- [POSIX Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [ShellCheck](https://www.shellcheck.net/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

*This style guide is a living document. Update as needed to reflect evolving best practices and project needs.*
