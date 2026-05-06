#!/bin/sh
#DOC Format .rs files under the project root (default) or given paths
#DOC Formatters: leptosfmt → rustfmt (if leptosfmt available), rustfmt alone otherwise
#DOC Intended for use as a treefmt formatter; treefmt passes individual files.
#DOC When run standalone with no arguments, discovers files from the project root.
# shellcheck enable=all

set -eu

#╔═══════════════════════════════════════════════════════════╗
#║ State                                                     ║
#╚═══════════════════════════════════════════════════════════╝
CHECK=""
DEBUG=""
FILES=""
FAILED=0
ERRTMP=""
FILETMP=""

#? Verbosity: 0 = quiet, 1 = normal (default), 2 = verbose
#? DEBUG implies VERBOSITY=2 and passes --verbose down to formatters
VERBOSITY=1

#╔═══════════════════════════════════════════════════════════╗
#║ Utilities                                                 ║
#╚═══════════════════════════════════════════════════════════╝
die() {
  printf 'fmt-rust: %s\n' "$*" >&2
  exit 1
}

pass() { [ "${VERBOSITY}" -ge 1 ] && printf 'fmt-rust: ✔ %s\n' "$*" || true; }
fail() {
  printf 'fmt-rust: ✗ %s\n' "$*" >&2
  FAILED=1
}
info() { [ "${VERBOSITY}" -ge 2 ] && printf 'fmt-rust: %s\n' "$*" >&2 || true; }

#? Replay captured formatter stderr to the caller's stderr line by line
relay_err() {
  while IFS= read -r _line; do
    printf '%s\n' "${_line}"
  done <"${ERRTMP}" >&2
}

#╔═══════════════════════════════════════════════════════════╗
#║ Argument Parsing                                          ║
#╚═══════════════════════════════════════════════════════════╝
usage() {
  printf 'usage: %s [options] [files...]\n' "${0##*/}"
  printf '\n'
  printf 'options:\n'
  printf '  -x, --check    check formatting without modifying files\n'
  printf '  -q, --quiet    suppress all output except errors\n'
  printf '  -V, --verbose  show formatter and discovery details\n'
  printf '  -d, --debug    verbose mode plus formatter-level verbosity\n'
  printf '  -h, --help     show this message and exit\n'
  printf '\n'
  printf 'files:\n'
  printf '  one or more .rs files or directories to format\n'
  printf '  if none are given, files are discovered from the\n'
  printf '  project root (via git rev-parse) or the current dir\n'
  printf '\n'
  printf 'formatters (in order of preference):\n'
  printf '  leptosfmt --rustfmt  single-pass: leptosfmt then rustfmt\n'
  printf '  rustfmt              fallback when leptosfmt is unavailable\n'
  printf '\n'
  printf 'discovery (in order of preference):\n'
  printf '  fd             respects .gitignore, excludes hidden dirs\n'
  printf '  git ls-files   exact .gitignore semantics\n'
  printf '  find           fallback, prunes .git/ target/ archives/\n'
}

parse_arguments() {
  for arg in "$@"; do
    case "${arg}" in
    -h | --help)
      usage
      exit 0
      ;;
    -x | --check) CHECK="1" ;;
    -q | --quiet) VERBOSITY=0 ;;
    -V | --verbose) VERBOSITY=2 ;;
    -d | --debug)
      DEBUG="1"
      VERBOSITY=2
      ;;
    -*) die "unknown flag: ${arg} (try --help)" ;;
    *) FILES="${FILES} ${arg}" ;;
    esac
  done
}

#╔═══════════════════════════════════════════════════════════╗
#║ File Discovery                                            ║
#╚═══════════════════════════════════════════════════════════╝
find_root() {
  if command -v git >/dev/null 2>&1; then
    git rev-parse --show-toplevel 2>/dev/null || pwd
  else
    pwd
  fi
}

discover_files() {
  _root="$1"

  if command -v fd >/dev/null 2>&1; then
    #? fd respects .gitignore and excludes hidden dirs by default
    fd --type file --extension rs --exclude archives . "${_root}"
  elif command -v git >/dev/null 2>&1 && [ -d "${_root}/.git" ]; then
    #? git ls-files gives exact .gitignore semantics via pathspec exclusions
    git -C "${_root}" ls-files --cached --others --exclude-standard \
      -- ':!*/.*' ':!archives/*' '*.rs'
  else
    #? Fallback: prune .git/, target/, archives/, and hidden dirs
    find "${_root}" \( \
      -path '*/.git' -o \
      -path '*/target' -o \
      -path '*/archives' -o \
      -path '*/.*' \
      \) -prune -o -type f -name '*.rs' -print
  fi
}

#╔═══════════════════════════════════════════════════════════╗
#║ Formatters                                                ║
#╚═══════════════════════════════════════════════════════════╝
fmt_with_leptosfmt() {
  _file="$1"

  if [ -n "${DEBUG}" ]; then
    #? Debug: run leptosfmt and rustfmt as separate in-place invocations so
    #? their natural stdout (config dump, ✅ lines, summary) flows freely.
    #? The --stdin --rustfmt pipeline cannot be used here because it captures
    #? stdout for the formatted content, permanently swallowing diagnostics.
    if [ -n "${CHECK}" ]; then
      if leptosfmt --experimental-tailwind --check "${_file}" &&
        rustfmt --check --verbose "${_file}"; then
        pass "${_file}"
      else
        fail "${_file}"
      fi
    else
      if leptosfmt --experimental-tailwind "${_file}" &&
        rustfmt --verbose "${_file}"; then
        pass "${_file}"
      else
        fail "${_file}"
      fi
    fi
  else
    #? Normal: single-pass stdin pipeline; capture stderr for replay on failure
    if [ -n "${CHECK}" ]; then
      if leptosfmt --stdin --rustfmt --experimental-tailwind --quiet --check \
        <"${_file}" >/dev/null 2>"${ERRTMP}"; then
        pass "${_file}"
      else
        relay_err
        fail "${_file}"
      fi
    else
      if leptosfmt --stdin --rustfmt --experimental-tailwind --quiet \
        <"${_file}" >"${FILETMP}" 2>"${ERRTMP}"; then
        mv "${FILETMP}" "${_file}"
        pass "${_file}"
      else
        relay_err
        fail "${_file}"
      fi
    fi
  fi
}

fmt_with_rustfmt() {
  _file="$1"

  if [ -n "${DEBUG}" ]; then
    #? Debug: pass --verbose and let all formatter output flow through live
    if [ -n "${CHECK}" ]; then
      if rustfmt --check --verbose "${_file}"; then
        pass "${_file}"
      else
        fail "${_file}"
      fi
    else
      if rustfmt --verbose "${_file}"; then
        pass "${_file}"
      else
        fail "${_file}"
      fi
    fi
  else
    #? Normal: capture stderr so we can replay it only on failure
    if [ -n "${CHECK}" ]; then
      if rustfmt --check "${_file}" 2>"${ERRTMP}"; then
        pass "${_file}"
      else
        relay_err
        fail "${_file}"
      fi
    else
      if rustfmt "${_file}" 2>"${ERRTMP}"; then
        pass "${_file}"
      else
        relay_err
        fail "${_file}"
      fi
    fi
  fi
}

fmt_file() {
  _file="$1"

  if command -v leptosfmt >/dev/null 2>&1; then
    info "leptosfmt+rustfmt: ${_file}"
    fmt_with_leptosfmt "${_file}"
  elif command -v rustfmt >/dev/null 2>&1; then
    info "rustfmt: ${_file}"
    fmt_with_rustfmt "${_file}"
  else
    die "neither leptosfmt nor rustfmt found"
  fi
}

#╔═══════════════════════════════════════════════════════════╗
#║ Formatting Dispatch                                       ║
#╚═══════════════════════════════════════════════════════════╝
fmt_dir() {
  _dir="$1"
  #? Assign separately so discover_files exit code is not masked (SC2312)
  _found=$(discover_files "${_dir}")
  [ -n "${_found}" ] || {
    info "no .rs files found under ${_dir}"
    return
  }
  while IFS= read -r file; do
    fmt_file "${file}"
  done <<DISCOVERED
${_found}
DISCOVERED
}

#╔═══════════════════════════════════════════════════════════╗
#║ Main                                                      ║
#╚═══════════════════════════════════════════════════════════╝
main() {
  parse_arguments "$@"

  ERRTMP=$(mktemp)
  FILETMP=$(mktemp)
  trap 'rm -f "${ERRTMP}" "${FILETMP}"' EXIT INT TERM

  if [ -z "${FILES}" ]; then
    ROOT=$(find_root)
    info "scanning ${ROOT}"
    fmt_dir "${ROOT}"
  else
    for entry in ${FILES}; do
      if [ -f "${entry}" ]; then
        fmt_file "${entry}"
      elif [ -d "${entry}" ]; then
        info "scanning ${entry}"
        fmt_dir "${entry}"
      else
        die "not a file or directory: ${entry}"
      fi
    done
  fi

  exit "${FAILED}"
}

main "$@"
