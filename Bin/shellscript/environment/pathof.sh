#!/bin/sh
#TODO: Review output options and ensure file creation is POSIX-compliant
# shellcheck disable=2030,2031

main() {
  set -e
  set -u
  trap cleanup EXIT INT TERM
  set_defaults
  parse_arguments "$@"
  execute_process
}

set_defaults() {
  #| Script Information
  scr_name="pathof.sh"
  scr_desc="Find the path of a file or directory in the current or parent directories"
  scr_usage="Usage: ${scr_name} --base <path> --direction <up|down|both> --items <item1 item2 ...>"
  scr_version="0.1.0"

  #| Global Variables
  debug=0
  LF="$(printf '\n')"
  delimiter="$(printf '\037')"
  IFS="${delimiter}"
  CMD_FD="${CMD_FD:-"$(command -v fd 2>/dev/null)"}"

  #| Process Variables
  base="${PRJ_ROOT:-"$(get_base)"}"
  direction="both"
  items=""
  case_sensitive=0
  max_depth=100
  type="all"
  fuzzy_match=1
  smart_exec=1
  get_home=0
}

parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help)
      pout_guide
      exit 0
      ;;
    -v | --version)
      printf "%s\n" "${scr_name} (${scr_version})"
      exit 0
      ;;
    -V | --debug)
      debug=1
      ;;
    --type)
      type="$2"
      shift
      ;;
    -[bB] | --base)
      base="$2"
      shift
      ;;
    -[dD] | --direction)
      direction="$2"
      shift
      ;;
    --up)
      type="path"
      direction="up"
      ;;
    --down)
      type="path"
      direction="down"
      ;;
    --both)
      type="path"
      direction="both"
      ;;
    --exe)
      type="exe"
      ;;
    --case-sensitive)
      case_sensitive=1
      ;;
    --fuzzy)
      fuzzy_match=1
      ;;
    --no-fuzzy)
      fuzzy_match=0
      ;;
    -[eE] | --exact)
      fuzzy_match=0
      ;;
    --smart | --extensive | --deep)
      smart_exec=1
      type="exe"
      ;;
    --no-smart | --no-extensive | --no-deep)
      smart_exec=0
      ;;
    --shallow)
      smart_exec=0
      fuzzy_match=0
      ;;
    --all)
      type="all"
      ;;
    --max-depth)
      max_depth="$2"
      shift
      ;;
    -o | --output)
      output_file="$2"
      shift
      ;;
    -p | --print)
      print_stdout=1
      ;;
    --get-home)
      get_home=1
      ;;
    -[lL] | --list)
      list_mode=1
      ;;
    --limit)
      result_limit="$2"
      shift
      ;;
    --sort)
      sort_by="$2"
      shift
      ;;
    --format)
      output_format="$2"
      shift
      ;;
    -[iI] | --item)
      items="${items:+${items}${delimiter}}$2"
      shift
      ;;
    *)
      items="${items:+${items}${delimiter}}$1"
      ;;
    esac
    shift
  done

  case "${get_home:-}" in
  0 | '' | false | no | off | [nN]*) validate_arguments ;;
  *)
    printf "%s" "${base}"
    exit 0
    ;;
  esac
}

validate_arguments() {
  #@ Validate required arguments
  check_required() {
    [ -z "$1" ] || return 0
    printf "%s\n" "<\ ERROR /> Missing argument: $2" >&2
    printf "%s\n" "${scr_usage}" >&2
    return 1
  }
  check_required "${base:-}" "base"
  check_required "${items:-}" "item"

  #@ Validate direction
  case "${direction}" in
  up | down | both | exe) ;;
  *)
    printf "Invalid direction: Options are 'exe', 'up', 'down' and 'both'\n" >&2
    return 1
    ;;
  esac

  pout_debug "BASE: ${base}"
  pout_debug "DIRECTION: ${direction}"
  pout_debug "ITEMS: ${items}"
  pout_debug "TYPE: ${type}"
  pout_debug "FUZZY MATCH: ${fuzzy_match}"
  pout_debug "CASE SENSITIVE: ${case_sensitive}"
}

pout_debug() {
  case "${get_home:-}" in
  0 | '' | false) return 0 ;;
  *) printf "[DEBUG] %s\n" "$*" >&2 ;;
  esac
}

get_base() {
  root_dir=""

  #@ Find Git repository root first
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    root_dir="$(git rev-parse --show-toplevel)"
  else
    root_items=".git flake.nix Cargo.toml package.json go.mod"
    dir="$(pwd)" # Start at current directory if not already set
    while [ "${dir}" != "/" ]; do
      for item in ${root_items}; do
        if [ -e "${dir}/${item}" ]; then
          root_dir="${dir}"
          pout_debug "Found root directory: ${root_dir} using children: ${root_items}"
          #@ Break out of both loops when a root item is found
          break 2
        fi
      done

      #@ Move up to parent directory
      if ! dir="$(dirname "${dir}")"; then
        pout_debug "dirname command failed for ${dir}"
        break
      fi
    done
  fi

  #@ Return the root directory only if it's absolute
  if [ "${root_dir:-}" = "." ] || [ -z "${root_dir:-}" ]; then
    pout_debug "Could not determine project root, using current directory"
    current_dir="$(pwd)" || current_dir="."
    printf "%s" "${current_dir}"
    return 0
  fi

  #@ Return the root directory
  printf "%s" "${root_dir}"
}

find_path() {
  #@ Initialize variables
  search_path="${base}"
  search_pattern=""
  search_type=""
  search_item=""
  search_results=""
  search_results_count=0

  #@ Parse options
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --down* | down*) search_type="downward" ;;
    --up* | up*) search_type="upward" ;;
    --from)
      [ -n "$2" ] && {
        search_path="$2"
        shift
      }
      ;;
    --for* | for*)
      [ -n "$2" ] && {
        search_item="$2"
        shift
      }
      ;;
    *) search_item="$1" ;;
    esac
    shift
  done

  #@ Validate required parameters
  if [ -z "${search_type:-}" ]; then
    printf "%s\n" "<\ ERROR /> Missing argument: direction" >&2
    printf "%s\n" "${scr_usage}" >&2
    return 1
  else
    search_type_proper="$(
      printf "%s" "${search_type}" | sed 's/^\(.\)/\u\1/'
    )"
  fi

  if [ -z "${search_item:-}" ]; then
    printf "%s\n" "<\ ERROR /> Missing argument: item" >&2
    printf "%s\n" "${scr_usage}" >&2
    return 1
  else
    search_pattern="*${search_item}*"
  fi

  search_downwards() {
    if [ -x "${CMD_FD:-}" ] && [ -x "${CMD_FD}" ]; then
      "${CMD_FD}" \
        --hidden \
        --absolute-path \
        --max-depth "${max_depth}" \
        --glob "${search_pattern}" \
        "${search_path}" \
        2>/dev/null
    else
      timeout 5 find "${search_path}" \
        -maxdepth "${max_depth}" \
        -iname "${search_pattern}" \
        2>/dev/null || true
    fi
  }

  search_upwards() {
    #@ Initialize variables
    res=""
    found=""
    loop_guard=0

    #@ Collect search results from parent directories
    while [ "${search_path}" != "/" ]; do

      loop_guard=$((loop_guard + 1))
      [ "${loop_guard}" -gt 100 ] && {
        pout_debug "Upward search exceeded maximum iterations (100), stopping"
        break
      }
      if [ -x "${CMD_FD:-}" ] && [ -x "${CMD_FD}" ]; then
        found="$(
          "${CMD_FD}" \
            --hidden \
            --absolute-path \
            --glob "${search_pattern}" \
            --max-depth 1 \
            "${search_path}" \
            2>/dev/null
        )" || true
      else
        found="$(find "${search_path}" -maxdepth 1 -iname "${search_pattern}" 2>/dev/null)" || true
      fi

      if [ -n "${found}" ]; then
        res="${res}${res:+${LF}}${found}"
      fi

      #@ Move up to parent directory, with proper error checking
      if ! search_path="$(dirname "${search_path}")"; then
        pout_debug "dirname failed for ${search_path}, stopping upward search"
        break
      fi
    done

    #@ Return results
    printf "%s" "${res:-}"
  }

  #@ Fetch search results
  case "${search_type}" in
  upward) search_results="$(search_upwards)" ;;
  downward | *) search_results="$(search_downwards)" ;;
  esac

  #@ Debug results
  pout_debug "$(
    printf "Searching %s for '%s' from '%s'" "$(
      printf "%s" "${search_type}" |
        tr '[:upper:]' '[:lower:]' || true
    )" "${search_item}" "${search_path}"
  )"

  if [ -n "${search_results}" ]; then
    printf "%s" "${search_results}" |
      while IFS= read -r line || [ -n "${line}" ]; do
        search_results_count=$((search_results_count + 1))
        pout_debug "$(
          printf "%s search yielded <\ %s /> %s" \
            "${search_type_proper}" "${search_results_count}" "${line}"
        )"
      done
  else
    pout_debug "${search_type_proper} search yielded no results"
  fi

  #@ Process results by match quality
  if [ -n "${search_results}" ]; then
    printf "%s" "${search_results}" |
      awk -v target="${search_item}" '
        function basename(path) {
          sub(".*/", "", path)
          return path
        }
        {
          file = basename($0)
          if (index(file, target) == 1) {
            print "3", $0  # Exact match at start - highest priority
          } else if (file == target) {
            print "2", $0  # Exact filename match - high priority
          } else {
            # Score matches by components
            split($0, parts, "/")
            score = 0
            for(i in parts) {
              if(parts[i] ~ target) score++
            }
            print "1." score, $0
          }
        }' |
      sort -r | cut -d' ' -f2-
  fi

  #@ Return results
  printf "%s" "${search_results}"
}

find_exe() {
  #@ Search for executable in PATH
  if command -v "${1}" 2>/dev/null; then
    search_result="$(command -v "${1}" 2>/dev/null)"
  else
    search_result=""
  fi

  #@ Extended search for executables with common extensions if not found
  if [ -z "${search_result}" ] && [ "${smart_exec:-0}" -eq 1 ]; then
    for ext in ".sh" ".exe" ".cmd" ".bat" ".rs" ".py" ".rb"; do
      potential_exe="${1}${ext}"
      pout_debug "Trying ${potential_exe}"

      if command -v "${potential_exe}" 2>/dev/null; then
        search_result="$(command -v "${potential_exe}")"
        break
      else
        search_result="$(find_path --downwards --for "${potential_exe}")"
        if [ -n "${search_result}" ]; then
          break
        else
          pout_debug "No results for ${potential_exe}"
        fi
      fi

    done
  fi

  #@ Return search result
  printf "%s" "${search_result}"
}

execute_process_OLD() {
  #@ Initialize variables
  process_item=""
  process_results=""
  process_result=""

  #@ Define helper functions
  for_exe() {
    #@ Initialize search result
    search_result=""

    #@ Search for executable in PATH
    search_result="$(find_exe "${1}")"

    #@ Return search result
    printf "%s" "${search_result}"
  }

  for_path() {
    #@ Initialize search result
    search_result=""

    #@ Perform search based on direction
    case "${2}" in
    up)
      #@ Search only in parent directories
      search_result="$(find_path --upwards --for "${1}")"
      ;;
    down) #@ Search only in child directories
      search_result="$(
        find_path --downwards --for "${1}"
      )"
      ;;
    both | *)
      #@ Try downward search first (typically faster)
      search_result="$(find_path --downwards --for "${1}")"

      #@ If nothing found, try upward search
      if [ -z "${search_result}" ]; then
        search_result="$(find_path --upwards --for "${1}")"
      fi
      ;;
    esac

    #@ Return search result
    printf "%s" "${search_result}"
  }

  for_all() {
    #@ Initialize search result
    search_result=""

    #@ Try paths search first
    search_result="$(for_exe "${1}")"

    #@ If nothing found, try path search
    [ -n "${search_result}" ] || {
      search_result="$(for_path "${1}" "${2}")"
    }

    #@ Return search result
    printf "%s" "${search_result}"
  }

  #@ Process each item
  for process_item in ${items}; do
    pout_debug "ITEM: ${process_item}"

    #@ Process based on requested types
    case "${type:-all}" in
    exe)
      #@ Only search for executables
      process_result="$(find_exe "${process_item}")"
      ;;
    path)
      process_result="$(for_path "${process_item}" "${direction}")"
      ;;
    all | "")
      process_result="$(for_all "${process_item}" "${direction}")"
      ;;
    *)
      pout_debug "Unknown file type: ${type}, falling back to all"
      process_result="$(for_all "${process_item}" "${direction}")"
      ;;
    esac

    #@ Skip if no result was found
    if [ -n "${process_result}" ]; then
      process_results="${process_results}${process_results:+${LF}}${process_result}"
      break
    else
      continue
    fi
  done

  #@ Display all results in debug mode
  [ -n "${process_results}" ] || {
    pout_debug "No results found"
    return 1
  }

  #@ Retrieve the result located closest to the base directory
  process_result="$(
    printf "%s" "${process_results}" |
      awk '{
        file=$0
        gsub("[^/]", "", file)
        print length(file), $0
      }' |
      sort -n | cut -d' ' -f2- | head -n1
  )"

  #@ Return result
  printf "%s" "${process_result}"
}

execute_output() {
  #@ Initialize variables
  results="$1"
  formatted_output=""

  #@ If no results found, exit with error
  if [ -z "${results}" ]; then
    pout_debug "No results to output"
    return 1
  fi

  #@ Format results based on output format
  case "${output_format:-plain}" in
  json)
    #@ Format as JSON array
    formatted_output="["
    first=true
    echo "${results}" | while IFS= read -r line || [ -n "${line}" ]; do
      if [ "${first}" = true ]; then
        formatted_output="${formatted_output}\n  \"${line}\""
        first=false
      else
        formatted_output="${formatted_output},\n  \"${line}\""
      fi
    done
    formatted_output="${formatted_output}\n]"
    ;;

  csv)
    # Format as CSV with path column
    formatted_output="path\n"
    echo "${results}" | while IFS= read -r line || [ -n "${line}" ]; do
      formatted_output="${formatted_output}\"${line}\"\n"
    done
    ;;

  plain | *)
    # Simple plain text output, one result per line
    formatted_output="${results}"
    ;;
  esac

  # Handle list mode result limiting
  if [ "${list_mode:-0}" -eq 1 ] && [ -n "${result_limit:-}" ]; then
    # Limit the number of results
    formatted_output="$(echo "${formatted_output}" | head -n "${result_limit}")"
    pout_debug "Limited results to ${result_limit} entries"
  fi

  # If we're in list mode, process all results based on sort option
  if [ "${list_mode:-0}" -eq 1 ] && [ -n "${sort_by:-}" ]; then
    case "${sort_by}" in
    name)
      # Sort by filename alphabetically
      formatted_output="$(echo "${formatted_output}" | sort -f)"
      pout_debug "Sorted results by name"
      ;;
    path)
      # Sort by full path alphabetically
      formatted_output="$(echo "${formatted_output}" | sort -f)"
      pout_debug "Sorted results by path"
      ;;
    time)
      # Sort by modification time (newest first)
      # This requires a temporary file to store results
      temp_file
      temp_file="$(mktemp)" || {
        pout_debug "Failed to create temporary file for time-based sorting"
        # Fall back to unsorted output
        :
      }

      if [ -f "${temp_file}" ]; then
        echo "${formatted_output}" >"${temp_file}"
        # Use stat to sort by modification time
        formatted_output="$(ls -t "$(cat "${temp_file}")" 2>/dev/null || cat "${temp_file}")"
        rm -f "${temp_file}"
        pout_debug "Sorted results by modification time"
      fi
      ;;
    distance | *)
      # Distance sorting is the default behavior and is already applied
      pout_debug "Results already sorted by distance"
      ;;
    esac
  fi

  # Output the results based on configuration
  if [ -n "${output_file:-}" ]; then
    # Write to specified output file
    printf "%s\n" "${formatted_output}" >"${output_file}" || {
      printf "Error: Failed to write to output file: %s\n" "${output_file}" >&2
      return 1
    }
    pout_debug "Wrote results to ${output_file}"
  fi

  # Print to stdout if requested or if no output file was specified
  if [ "${print_stdout:-0}" -eq 1 ] || [ -z "${output_file:-}" ]; then
    printf "%s\n" "${formatted_output}"
  fi

  return 0
}

execute_process() {
  #@ Initialize variables
  process_item=""
  process_results=""
  process_result=""
  all_results=""

  #@ Define helper functions
  for_exe() {
    #@ Initialize search result
    search_result=""

    #@ Search for executable in PATH
    search_result="$(find_exe "${1}")"

    #@ Return search result
    printf "%s" "${search_result}"
  }

  for_path() {
    #@ Initialize search result
    search_result=""

    #@ Perform search based on direction
    case "${2}" in
    up)
      #@ Search only in parent directories
      search_result="$(find_path --upwards --for "${1}")"
      ;;
    down) #@ Search only in child directories
      search_result="$(
        find_path --downwards --for "${1}"
      )"
      ;;
    both | *)
      #@ Try downward search first (typically faster)
      search_result="$(find_path --downwards --for "${1}")"

      #@ If nothing found, try upward search
      if [ -z "${search_result}" ]; then
        search_result="$(find_path --upwards --for "${1}")"
      fi
      ;;
    esac

    #@ Return search result
    printf "%s" "${search_result}"
  }

  for_all() {
    #@ Initialize search result
    search_result=""

    #@ Try paths search first
    search_result="$(for_exe "${1}")"

    #@ If nothing found, try path search
    [ -n "${search_result}" ] || {
      search_result="$(for_path "${1}" "${2}")"
    }

    #@ Return search result
    printf "%s" "${search_result}"
  }

  #@ Process each item
  for process_item in ${items}; do
    pout_debug "ITEM: ${process_item}"

    #@ Process based on requested types
    case "${type:-all}" in
    exe)
      #@ Only search for executables
      process_result="$(find_exe "${process_item}")"
      ;;
    path)
      process_result="$(for_path "${process_item}" "${direction}")"
      ;;
    all | "")
      process_result="$(for_all "${process_item}" "${direction}")"
      ;;
    *)
      pout_debug "Unknown file type: ${type}, falling back to all"
      process_result="$(for_all "${process_item}" "${direction}")"
      ;;
    esac

    #@ Collect all results for list mode
    if [ "${list_mode:-0}" -eq 1 ] && [ -n "${process_result}" ]; then
      all_results="${all_results}${all_results:+${LF}}${process_result}"
    else
      #@ Skip if no result was found in single result mode
      if [ -n "${process_result}" ]; then
        process_results="${process_results}${process_results:+${LF}}${process_result}"
        break
      else
        continue
      fi
    fi
  done

  #@ Handle list mode
  if [ "${list_mode:-0}" -eq 1 ]; then
    #@ Use all collected results
    process_results="${all_results}"
  else
    #@ Retrieve the result located closest to the base directory
    process_result="$(
      printf "%s" "${process_results}" |
        awk '{
          file=$0
          gsub("[^/]", "", file)
          print length(file), $0
        }' |
        sort -n | cut -d' ' -f2- | head -n1
    )"

    #@ Use single result for output
    process_results="${process_result}"
  fi

  #@ Display all results in debug mode
  [ -n "${process_results}" ] || {
    pout_debug "No results found"
    return 1
  }

  #@ Process and output the results
  execute_output "${process_results}"
}

cleanup() {
  #@ Unset all variables to prevent leakage
  unset base items direction debug delimiter IFS CMD_FD
  unset scr_name scr_desc scr_usage scr_version scr_guide
  unset search_base search_item search_direction LF
  unset search_path search_pattern search_type search_item
  unset search_results search_results_count search_type_proper
  unset search_type_proper search_type_proper search_type_proper
  unset process_item process_results search_result process_result
}

pout_guide() {
  cat <<EOF
${scr_name} - Intelligent Path Finder

USAGE:
  ${scr_name} [OPTIONS] [PATTERN]

DESCRIPTION:
  Recursively searches for files, directories or executables in parent
  or child directories. Provides smart detection of project roots and
  executables in PATH.

SEARCH DIRECTION OPTIONS:
  --up                Search in parent directories only
  --down              Search in child directories only
  --both              Search in both directions (default: smart detection)
  -d, --direction DIR Specify search direction (up|down|both)
  -b, --base PATH     Starting directory for search (default: current directory)

SEARCH TYPE OPTIONS:
  --exe               Search for executables in PATH and directories
  --all               Search for all file types (default)
  --type TYPE         Specify type to search for (file|dir|exe|all)

MATCHING BEHAVIOR:
  -e, --exact         Use exact name matching (disables fuzzy matching)
  --shallow           Combine exact matching with non-extensive search
  --case-sensitive    Enable case-sensitive search
  --fuzzy             Enable fuzzy name matching (default)
  --no-fuzzy          Disable fuzzy name matching

SEARCH DEPTH CONTROL:
  --max-depth NUM     Limit search depth (default: 100)
  --smart, --deep     Perform extensive search for executables (default)
  --no-smart          Disable extensive executable search

ITEM SPECIFICATION:
  -i, --item PATTERN  File pattern to search for (can be used multiple times)
                      Without this flag, the pattern is set to the last argument(s)

OUTPUT CONTROL:
  -o, --output FILE   Output search results to file (default: stdout)
  -p, --print         Print search results to stdout
  -l, --list          Return all matching results instead of just the closest
  --limit NUM         Limit number of results when using --list (default: 50)
  --sort TYPE         Sort results by (distance|name|path|time) (default: distance)
  --format FORMAT     Output format (plain|json|csv) (default: plain)

GENERAL OPTIONS:
  -h, --help          Show this help message
  -v, --version       Show version information
  -V, --debug         Enable debug output

EXAMPLES:
  # Find .gitignore in parent directories
  ${scr_name} --up .gitignore

  # Search for index.html under /tmp
  ${scr_name} --down --base /tmp index.html

  # Find closest executable named 'cargo'
  ${scr_name} --exe --up cargo

  # Find exact match for 'README.md' in current project
  ${scr_name} --exact README.md

  # Search for multiple items
  ${scr_name} --item "*.js" --item "*.ts"

DEFAULT BEHAVIOR:
  • Starting location: Current directory or detected project root
  • Search direction: Checks child directories first, then parents
  • Maximum depth: 100 directory levels
  • File types: All files and directories
  • Case sensitivity: Case-insensitive matching
  • Matching method: Fuzzy matching enabled
  • Smart executable search: Enabled
  • Output: Single closest match (use --list for multiple results)

PROJECT ROOT DETECTION:
  Automatically detects project roots using common markers:
  • Git repositories (.git)
  • Nix flakes (flake.nix)
  • Node.js (package.json)
  • Rust (Cargo.toml)
  • Go (go.mod)
  • And other common project files

NOTES:
  • By default, returns the located path closest to the starting directory
  • With --list, returns all matches sorted by distance from starting point
  • When using --exe, searches both PATH and directories
  • Multiple search patterns can be specified with repeated --item flags
  • Exit code 0 indicates success (item found), non-zero indicates failure
EOF
}

main "$@"
