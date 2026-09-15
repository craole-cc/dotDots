#!/bin/sh
# shellcheck disable=SC2154,SC2163,SC2329
#? These are DEFAULTS, not forced values -- `:` is a no-op builtin, so
#? `: "${VAR:=x}"` only sets VAR when it's unset/empty, leaving room for
#? a caller (e.g. an RC file sourcing this on every shell startup) to
#? export DEBUG_DOTS_BIN=1 beforehand to opt into diagnostics for one
#? shell without editing this file. The previous unconditional
#? `DEBUG_DOTS_BIN=1` forced the full STAGE DEBUG DUMP on every single
#? source with no way to turn it off short of editing this file --
#? exactly wrong for something meant to run on every shell startup.
: "${DOTS_BINIT_SKIP:=0}"
: "${DEBUG_DOTS_BIN:=0}"
: "${DEBUG_DOTS_ENV:=0}"

# ── Environment Module ────────────────────────────────────────────────────────

init_env() {
  resolve_dots || return 1

  # ── DOTS Environment Variables ────────────────────────────────────────
  assign_var DEBUG_DOTS_BIN 0
  assign_var DEBUG_DOTS_ENV 0
  assign_var DOTS_BINIT_SKIP 0
  assign_path DOTS_CFG "${DOTS}" "Configuration"
  assign_path DOTS_LIB "${DOTS}" "Libraries"
  assign_path DOTS_LIB_BASH "${DOTS_LIB}" "bash"
  assign_path DOTS_LIB_CMD "${DOTS_LIB}" "cmd"
  assign_path DOTS_LIB_NIX "${DOTS_LIB}" "nix"
  assign_path DOTS_LIB_NU "${DOTS_LIB}" "nushell"
  assign_path DOTS_LIB_PS "${DOTS_LIB}" "powershell"
  assign_path DOTS_LIB_PY "${DOTS_LIB}" "python"
  assign_path DOTS_LIB_RS "${DOTS_LIB}" "rust"
  assign_path DOTS_LIB_SH "${DOTS_LIB}" "posix"
  assign_path DOTS_LIB_XML "${DOTS_LIB}" "xml"
  assign_path DOTS_BIN "${DOTS}" "Bin"
  assign_path DOTS_BINIT "${DOTS_LIB_SH}" "base" "binit"
  assign_var DOTS_BINIT_ACTION "run"

  #? Registry of what this module set, for dump_stage_vars. Plain
  #? (unexported) bookkeeping vars -- only read within this same shell.
  DOTS_VARS_ENV="DOTS DOTS_CFG DOTS_LIB DOTS_LIB_BASH DOTS_LIB_CMD DOTS_LIB_NIX DOTS_LIB_NU DOTS_LIB_PS DOTS_LIB_PY DOTS_LIB_RS DOTS_LIB_SH DOTS_LIB_XML DOTS_BIN DOTS_BINIT DOTS_BINIT_ACTION DOTS_BINIT_SKIP DEBUG_DOTS_BIN DEBUG_DOTS_ENV"

  # ── XDG Environment ────────────────────────────────────────────────────
  resolve_uid
  resolve_home || return 1

  assign_path XDG_CACHE_HOME "${HOME}" ".cache"
  assign_path XDG_CONFIG_HOME "${HOME}" ".config"
  assign_path XDG_DATA_HOME "${HOME}" ".local/share"
  assign_path XDG_BIN_HOME "${XDG_DATA_HOME%/*}" "bin"
  assign_list XDG_DATA_DIRS "${XDG_DATA_HOME}" "/usr/local/share:/usr/share"
  assign_path XDG_RUNTIME_DIR "/run/user" "${USER_ID}"

  DOTS_VARS_XDG="USER_ID HOME XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_BIN_HOME XDG_DATA_DIRS XDG_RUNTIME_DIR"

  # ── Base System Defaults ──────────────────────────────────────────────
  if command -v find_nix_profile_dir >/dev/null 2>&1; then
    NIX_PROFILE_DIR=$(find_nix_profile_dir)
    export NIX_PROFILE_DIR
  fi
  assign_path VSCODE_SERVER_DIR "${HOME}" ".vscode-server"

  DOTS_VARS_SYS="NIX_PROFILE_DIR VSCODE_SERVER_DIR"

  if [ "${DEBUG_DOTS_ENV:-0}" -eq 1 ]; then
    dump_stage_vars environment xdg system
  fi
}

# ── Binary Module ─────────────────────────────────────────────────────────────

init_bin() {
  assign_var DOTS_BINIT_DEPTH "10"
  assign_var DOTS_BINIT_IGNORE "review tmp archive"
  assign_var DOTS_BINIT_BLACKLIST_EXT "md txt json yaml yml xml html css js ts jsx tsx png jpg jpeg gif svg pdf doc docx xls xlsx ppt pptx zip tar gz bz2 7z log"
  assign_var BINIT_ACTION "run"

  #? One codepath indexes every tree that needs chmod+PATH treatment,
  #? instead of dots.sh doing Libraries/posix and a separate buildir
  #? script doing Bin/ with its own (buggy, unmaintained) logic. Add
  #? more trees here the same way if others show up later.
  #?
  #? NOTE: this drops buildir's per-directory `.ignore` file support --
  #? only DOTS_BINIT_IGNORE's directory-name list is honored now, the
  #? same as it always was for Libraries/posix. If Bin/ relied on an
  #? actual `.ignore` file for exclusions, add those directory names to
  #? DOTS_BINIT_IGNORE instead.
  DOTS_BINIT_TARGETS="${DOTS_LIB_SH}"
  [ -d "${DOTS_BIN}" ] && DOTS_BINIT_TARGETS="${DOTS_BINIT_TARGETS} ${DOTS_BIN}"
  export DOTS_BINIT_TARGETS

  DOTS_VARS_BIN="DOTS_BINIT_DEPTH DOTS_BINIT_IGNORE DOTS_BINIT_BLACKLIST_EXT DOTS_BINIT_TARGETS BINIT_ACTION DOTS_PATH PATH"

  binit
}

# ── Global Helper Library Initializer ─────────────────────────────────────────

init_lib() {
  is_truthy() {
    case "${1:-}" in
    1 | [Tt][Rr][Uu][Ee] | [Yy][Ee][Ss] | [Oo][Nn] | [Ee][Nn][Aa][Bb][Ll][Ee][Dd] | [Yy])
      return 0
      ;;
    *) return 1 ;;
    esac
  }

  join_path() {
    _jp_out="$1"
    shift
    for _jp_seg in "$@"; do
      _jp_out="${_jp_out}/${_jp_seg}"
    done
    printf '%s\n' "${_jp_out}"
  }

  assign_var() {
    _av_var="$1"
    eval "_av_val=\${${_av_var}:-}"
    if [ -z "${_av_val}" ]; then
      eval "${_av_var}=\"\$2\""
    fi
    export "${_av_var}"
    unset _av_var _av_val
  }

  assign_path() {
    _ap_var="$1"
    eval "_ap_val=\${${_ap_var}:-}"
    shift
    if [ -z "${_ap_val}" ]; then
      _ap_out=$(join_path "$@")
      eval "${_ap_var}=\"\${_ap_out}\""
      unset _ap_out
    fi
    export "${_ap_var}"
    unset _ap_var _ap_val
  }

  #? FIX: previously this always prepended "$2" onto the existing
  #? value, even when "$2" was already the leading entry. That meant
  #? re-sourcing dots.sh in the same shell (e.g. via ble.sh/direnv
  #? reload) kept growing XDG_DATA_DIRS by one duplicate entry every
  #? time. Now it only prepends if "$2" isn't already at the front.
  assign_list() {
    _al_var="$1"
    eval "_al_val=\${${_al_var}:-}"
    if [ -z "${_al_val}" ]; then
      eval "${_al_var}=\"\$2:\${3}\""
    else
      case "${_al_val}" in
      "$2:"*) ;; # already present at the front -- nothing to do
      *) eval "${_al_var}=\"\$2:\${_al_val}\"" ;;
      esac
    fi
    export "${_al_var}"
    unset _al_var _al_val
  }

  to_posix_path() {
    _tpp_path="$1"
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -u "${_tpp_path}"
    else
      printf '%s\n' "${_tpp_path}" | sed -e 's/\\/\//g' -e 's/^\([A-Za-z]\):/\/\1/'
    fi
  }

  get_user_id() {
    if command -v id >/dev/null 2>&1; then
      id -u 2>/dev/null && return 0
    fi
    [ -n "${UID:-}" ] && {
      printf '%s\n' "${UID}"
      return 0
    }
    _uname="${USER:-${USERNAME:-}}"
    if command -v getent >/dev/null 2>&1 && [ -n "${_uname}" ]; then
      getent passwd "${_uname}" | cut -d: -f3 2>/dev/null && return 0
    fi
    if [ -f /etc/passwd ] && [ -n "${_uname}" ]; then
      awk -F: -v user="${_uname}" '$1 == user { print $3 }' /etc/passwd 2>/dev/null && return 0
    fi
    [ -n "${USERNAME:-}" ] || [ -n "${USERPROFILE:-}" ] && {
      printf '%s\n' "1000"
      return 0
    }
    return 1
  }

  resolve_uid() {
    _uid="$(get_user_id)"
    if [ -n "${_uid}" ]; then
      assign_var USER_ID "${_uid}"
    else
      printf "dots: WARNING - Unable to resolve valid USER_ID\n" >&2
    fi
    unset _uid
  }

  resolve_home() {
    if [ -n "${HOME:-}" ] && [ -d "${HOME}" ]; then
      HOME=$(to_posix_path "${HOME}")
      export HOME
      return 0
    fi

    _res_home=""
    _uname="${USER:-${USERNAME:-}}"

    if [ -n "${USERPROFILE:-}" ]; then
      _res_home=$(to_posix_path "${USERPROFILE}")
    fi
    if [ -z "${_res_home}" ] && command -v getent >/dev/null 2>&1; then
      _res_home=$(getent passwd "${USER_ID:-${_uname}}" 2>/dev/null | cut -d: -f6)
    fi
    if [ -z "${_res_home}" ] && [ -f /etc/passwd ]; then
      if [ -n "${_uname}" ]; then
        _res_home=$(awk -F: -v u="${_uname}" '$1 == u { print $6 }' /etc/passwd 2>/dev/null)
      elif [ -n "${USER_ID:-}" ]; then
        _res_home=$(awk -F: -v uid="${USER_ID}" '$3 == uid { print $6 }' /etc/passwd 2>/dev/null)
      fi
    fi
    if [ -z "${_res_home}" ]; then
      if [ "${USER_ID:-}" = "0" ] || [ "${_uname}" = "root" ]; then
        _res_home="/root"
      elif [ -d "/c/Users/${_uname}" ]; then
        _res_home="/c/Users/${_uname}"
      elif [ -n "${_uname}" ]; then
        _res_home="/home/${_uname}"
      fi
    fi

    if [ -n "${_res_home}" ] && [ -d "${_res_home}" ]; then
      HOME="${_res_home}"
      export HOME
      unset _res_home _uname
      return 0
    fi

    printf "dots: FATAL - Unable to resolve valid HOME directory\n" >&2
    unset _res_home _uname
    return 1
  }

  resolve_dots() {
    if [ -n "${DOTS:-}" ] && [ ! -d "${DOTS}" ]; then
      printf "dots: WARNING - \$DOTS points to non-existent path '%s'. Resetting.\n" "${DOTS}" >&2
      unset DOTS
    fi

    if [ -z "${DOTS:-}" ] && command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      DOTS=$(git rev-parse --show-toplevel 2>/dev/null || true)
      [ -n "${DOTS}" ] && printf "dots: WARNING - \$DOTS was unset; resolved via git to '%s'\n" "${DOTS}" >&2
    fi

    if [ -z "${DOTS:-}" ]; then
      range_dir="${PWD:-$(pwd -P)}"
      while [ -n "${range_dir}" ] && [ "${range_dir}" != "/" ]; do
        if [ -d "${range_dir}/.git" ] && [ -f "${range_dir}/flake.nix" ] && [ -f "${range_dir}/.dotsrc" ]; then
          DOTS="${range_dir}"
          printf "dots: WARNING - \$DOTS was unset; discovered verified root anchor at '%s'\n" "${DOTS}" >&2
          break
        fi
        range_dir="${range_dir%/*}"
      done
      unset range_dir
    fi

    if [ -z "${DOTS:-}" ] || [ ! -d "${DOTS}" ]; then
      printf "dots: FATAL - Could not resolve \$DOTS via git or strict root anchors.\n" >&2
      return 1
    fi

    DOTS=$(to_posix_path "${DOTS}")
    export DOTS
  }

  require_binit_targets() {
    if [ -z "${DOTS_BINIT_TARGETS:-}" ]; then
      printf "dots: DOTS_BINIT_TARGETS is empty -- nothing to index.\n" >&2
      return 1
    fi
    for _rbt_target in ${DOTS_BINIT_TARGETS}; do
      if [ ! -d "${_rbt_target}" ]; then
        printf "dots: binit target is not a valid directory (got: '%s').\n" "${_rbt_target}" >&2
        return 1
      fi
    done
  }

  #| The one and only tree walk -- now across every directory in
  #? DOTS_BINIT_TARGETS (Libraries/posix, Bin/, whatever else gets
  #? added) in a single call, since rg/fd/find all accept multiple
  #? path arguments natively. Everything downstream -- chmod'ing,
  #? PATH-directory derivation, collision detection, and the dump-bins
  #? audit -- reads the SAME candidate list this produces instead of
  #? re-walking the tree.
  #?
  #? _always_ignore is skipped regardless of DOTS_BINIT_IGNORE: VCS internals
  #? in particular can be enormous (thousands of loose objects), and
  #? --hidden + --no-ignore together are exactly what lets rg/fd wander
  #? into them if they're not excluded explicitly.
  list_shebang_candidates() {
    out="$1"
    _always_ignore=".git .jj .hg .svn node_modules"

    if command -v rg >/dev/null 2>&1; then
      _rg_glob=""
      for dir in ${DOTS_BINIT_IGNORE} ${_always_ignore}; do _rg_glob="${_rg_glob} --glob !**/${dir}/**"; done
      # shellcheck disable=SC2086
      rg --files-with-matches --no-messages --hidden --no-ignore --multiline --pcre2 ${_rg_glob} '\A#!' ${DOTS_BINIT_TARGETS} >"${out}" 2>/dev/null
      printf "rg"
      return 0
    fi

    if command -v fd >/dev/null 2>&1; then
      _fd_exclude=""
      for dir in ${DOTS_BINIT_IGNORE} ${_always_ignore}; do _fd_exclude="${_fd_exclude} --exclude ${dir}"; done
      # shellcheck disable=SC2086
      fd --type f --hidden --no-ignore ${_fd_exclude} . ${DOTS_BINIT_TARGETS} >"${out}" 2>/dev/null
      printf "fd"
      return 0
    fi

    _prune=""
    for dir in ${DOTS_BINIT_IGNORE} ${_always_ignore}; do _prune="${_prune}${_prune:+ -o }-name ${dir}"; done
    : >"${out}"
    #? shellcheck disable=SC2086 -- DOTS_BINIT_TARGETS is intentionally
    #? word-split, one `find` root per target directory.
    for _target in ${DOTS_BINIT_TARGETS}; do
      if [ -n "${_prune}" ]; then
        # shellcheck disable=SC2086
        find "${_target}" \( -type d \( ${_prune} \) -prune \) -o -type f -print >>"${out}" 2>/dev/null
      else
        find "${_target}" -type f >>"${out}" 2>/dev/null
      fi
    done
    printf "find"
  }

  #| Single pass over the candidate list that produces everything the
  #? three downstream stages need:
  #?   GATHER_PENDING -- NUL-delimited paths that still need chmod +x
  #?   GATHER_DIRS    -- one directory per line, for PATH derivation
  #?   GATHER_NAMES   -- "basename<TAB>fullpath", for collision detection
  #?
  #? Previously make_executable, check_bin_collisions, and
  #? add_to_path each did their own `while read` loop over the same
  #? file list -- three full interpreter-level passes instead of one.
  #? On a large tree that's the dominant cost (discovery itself is a
  #? single fast rg/fd call). This merges them into one loop.
  #?
  #? FIX: the old make_executable/add_to_path implementations checked
  #? `${BLACKLIST_EXT}` (never set) instead of
  #? `${DOTS_BINIT_BLACKLIST_EXT}`, so the extension blacklist was
  #? silently a no-op in those two stages (only check_bin_collisions
  #? applied it correctly). That meant every non-executable file --
  #? .md, .json, .png, everything -- was opened to test for a shebang
  #? and considered for PATH, which is a second, independent source of
  #? the slowdown on top of the three-pass issue. Fixed here by using
  #? DOTS_BINIT_BLACKLIST_EXT consistently.
  gather_candidates() {
    _file_list="$1"
    _tier="$2"

    GATHER_PENDING="$(mktemp)"
    GATHER_DIRS="$(mktemp)"
    GATHER_NAMES="$(mktemp)"

    while IFS= read -r file; do
      [ -n "${file}" ] || continue

      ext="${file##*.}"
      case " ${DOTS_BINIT_BLACKLIST_EXT} " in
      *" ${ext} "*) continue ;;
      *) ;;
      esac

      #- chmod candidacy -----------------------------------------------
      if [ ! -x "${file}" ]; then
        if [ "${_tier}" = "rg" ]; then
          #> rg already filtered to files matching ^#! -- no need to
          #? re-read them here.
          printf '%s\0' "${file}" >>"${GATHER_PENDING}"
        else
          IFS= read -r first_line <"${file}" 2>/dev/null
          case "${first_line}" in
          "#!"*) printf '%s\0' "${file}" >>"${GATHER_PENDING}" ;;
          *) ;;
          esac
        fi
      fi

      #- PATH candidacy --------------------------------------------------
      dir="${file%/*}"
      [ -n "${dir}" ] && printf '%s\n' "${dir}" >>"${GATHER_DIRS}"

      #- collision candidacy ----------------------------------------------
      printf '%s\t%s\n' "${file##*/}" "${file}" >>"${GATHER_NAMES}"
    done <"${_file_list}"
  }

  make_executable() {
    time_stage "make_executable" _make_executable_impl "$@"
  }

  #? Consumes the NUL-delimited pending list built by gather_candidates.
  #? No longer walks the tree or re-checks extensions/exec-bit itself.
  _make_executable_impl() {
    _pending="$1"

    changed_count=0
    if [ -s "${_pending}" ]; then
      changed_count=$(tr -cd '\0' <"${_pending}" | wc -c)
      #> NUL-delimited so "path with space" is handled correctly --
      #? xargs' default whitespace splitting would break on it.
      xargs -0 chmod +x <"${_pending}"
    fi

    [ "${changed_count}" -gt 0 ] && printf "Made %s scripts executable\n" "${changed_count}" >&2
  }

  #| Detects executables sharing a basename across more than one
  #? directory in GATHER_NAMES. Once their directories are both on
  #? PATH, only one is actually reachable via a bare command name --
  #? silently, based on PATH order. This doesn't pick a winner (that's
  #? a real choice about directory priority only you can make); it
  #? makes the ambiguity visible instead of silent. Returns 1 if any
  #? collisions were found, 0 otherwise.
  check_bin_collisions() {
    _names="$1"

    _report=$(awk -F'\t' '
      {
        paths[$1] = paths[$1] $2 "\n"
        count[$1]++
      }
      END {
        n = 0
        for (name in count) {
          if (count[name] > 1) {
            n++
            printf "  COLLISION: \"%s\" found in %d locations:\n", name, count[name]
            printf "%s", paths[name]
          }
        }
        exit (n > 0) ? 1 : 0
      }
    ' "${_names}")
    _rc=$?

    if [ -n "${_report}" ]; then
      printf '%s\n' "${_report}" >&2
      printf "dots: bin name collision(s) found -- PATH order silently decides which one runs.\n" >&2
    fi

    return "${_rc}"
  }

  add_to_path() {
    time_stage "add_to_path" _add_to_path_impl "$@"
  }

  #? Consumes the directory list built by gather_candidates instead of
  #? re-deriving directories from the file list itself.
  _add_to_path_impl() {
    _dirs="$1"
    DOTS_PATH=""
    dir_count=0

    _sorted_dirs="$(mktemp)"
    sort -u "${_dirs}" >"${_sorted_dirs}"

    while IFS= read -r dir; do
      [ -n "${dir}" ] || continue
      case ":${PATH}:${DOTS_PATH}:" in
      *:"${dir}":*) ;;
      *)
        DOTS_PATH="${DOTS_PATH:+"${DOTS_PATH}:"}${dir}"
        dir_count=$((dir_count + 1))
        ;;
      esac
    done <"${_sorted_dirs}"
    rm -f "${_sorted_dirs}"

    if [ -n "${DOTS_PATH}" ]; then
      PATH="${DOTS_PATH}:${PATH}"
      export PATH
    fi
  }

  #? Removes the three GATHER_* temp files. Call after each binit run.
  cleanup_gather() {
    rm -f "${GATHER_PENDING:-}" "${GATHER_DIRS:-}" "${GATHER_NAMES:-}"
    unset GATHER_PENDING GATHER_DIRS GATHER_NAMES
  }

  #| Reads BINIT_ACTION only -- this script is meant to be `.`-sourced
  #? (`. binit`), and a sourced script taking positional arguments is
  #? awkward to control from a shell rc/profile (every caller would
  #? need to remember to pass them on each source, and they can't be
  #? "just set once and forget" the way an env var can). Everything
  #? this used to accept as a CLI flag is a variable instead:
  #?   BINIT_ACTION       run | executable | path | dump-vars |
  #?                      dump-bins | none        (default: run)
  #?   BINIT_DUMP_GROUPS  space-separated group names to scope a
  #?                      dump-vars action (e.g. "environment xdg");
  #?                      unset/empty dumps every group
  #?   DEBUG_DOTS_BIN        1 = print per-stage timing, and dump binary/PATH
  #?                             vars (incl. PATH, DOTS_PATH) after this dispatch
  #?   DEBUG_DOTS_ENV    1 = dump environment/xdg/system vars after init_env
  #?   DOTS_BINIT_SKIP           1 = skip init_bin entirely (see main())
  binit() {
    case "${BINIT_ACTION}" in
    --run | run)
      require_binit_targets || return 1

      _file_list="$(mktemp)"
      _tier=$(time_stage "discover" list_shebang_candidates "${_file_list}")

      time_stage "gather_candidates" gather_candidates "${_file_list}" "${_tier}"

      make_executable "${GATHER_PENDING}"
      check_bin_collisions "${GATHER_NAMES}" || :
      add_to_path "${GATHER_DIRS}"

      cleanup_gather
      rm -f "${_file_list}"
      ;;
    --executable | executable)
      require_binit_targets || return 1
      _file_list="$(mktemp)"
      _tier=$(time_stage "discover" list_shebang_candidates "${_file_list}")
      time_stage "gather_candidates" gather_candidates "${_file_list}" "${_tier}"
      make_executable "${GATHER_PENDING}"
      cleanup_gather
      rm -f "${_file_list}"
      ;;
    --path | path)
      require_binit_targets || return 1
      _file_list="$(mktemp)"
      _tier=$(time_stage "discover" list_shebang_candidates "${_file_list}")
      time_stage "gather_candidates" gather_candidates "${_file_list}" "${_tier}"
      add_to_path "${GATHER_DIRS}"
      cleanup_gather
      rm -f "${_file_list}"
      ;;
    dump-vars)
      # shellcheck disable=SC2086
      dump_stage_vars ${BINIT_DUMP_GROUPS:-}
      ;;
    dump-bins)
      require_binit_targets || return 1
      dump_stage_bins
      ;;
    none)
      # Skip running bin procedures entirely
      ;;
    *)
      printf "dots: BINIT_ACTION must be one of: run, executable, path, dump-vars, dump-bins, none (got: '%s')\n" "${BINIT_ACTION}" >&2
      ;;
    esac

    #? FIX: this used to check DEBUG_STAGE_BIN, a separate flag that
    #? nothing else in this file ever sets or documents. DEBUG_DOTS_BIN
    #? is the flag people actually set (see main()'s usage example) and
    #? already gates the per-stage timing metrics, so it now gates this
    #? dump too -- same pattern as DEBUG_DOTS_ENV gating the env dump.
    if [ "${DEBUG_DOTS_BIN:-0}" -eq 1 ]; then
      dump_stage_vars binary
    fi
  }
}

# ── Diagnostic & Timing Engine ───────────────────────────────────────────────

init_diagnostics() {
  #? Retrieve the current time in milliseconds since epoch (POSIX fallback chain)
  get_time_ms() {
    _gtm_out=""

    #{ 1. Try date with nanosecond support (%s%N -> ms)
    _gtm_out=$(date +%s%N 2>/dev/null)
    case "${_gtm_out}" in
    *[!0-9]*) ;; # Failed or returned literal 'N' (unsupported %N on standard POSIX date)
    '') ;;
    *)
      printf '%s\n' "$((_gtm_out / 1000000))"
      return 0
      ;;
    esac

    #{ 2. Try Python 3
    if command -v python3 >/dev/null 2>&1; then
      _gtm_out=$(python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null) && {
        printf '%s\n' "${_gtm_out}"
        return 0
      }
    fi

    #{ 3. Try Perl
    if command -v perl >/dev/null 2>&1; then
      _gtm_out=$(perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000' 2>/dev/null) && {
        printf '%s\n' "${_gtm_out}"
        return 0
      }
    fi

    #{ 4. POSIX fallback: seconds precision
    _secs="$(date +%s)"
    printf '%s000\n' "${_secs}"
  }

  #? Time execution of a stage block
  time_stage() {
    _ts_name="$1"
    shift

    _ts_start=$(get_time_ms)
    "$@"
    _ts_rc=$?
    _ts_end=$(get_time_ms)

    _ts_elapsed=$((_ts_end - _ts_start))

    if [ "${DEBUG_DOTS_BIN:-0}" -ge 1 ]; then
      printf "dots: [STAGE METRIC] %-18s completed in %4d ms (exit: %d)\n" \
        "'${_ts_name}'" "${_ts_elapsed}" "${_ts_rc}" >&2
    fi

    return "${_ts_rc}"
  }

  #| Colon-separated variables (PATH, XDG_DATA_DIRS, DOTS_PATH) are
  #? unreadable as a single 400-character line, so they get split one
  #? entry per line, numbered, with a count in the header and any
  #? duplicate entries flagged inline -- duplicates on PATH/XDG_DATA_DIRS
  #? are exactly the kind of thing this dump exists to surface.
  print_list_var() {
    _plv_name="$1"
    _plv_val="$2"

    if [ -z "${_plv_val}" ] || [ "${_plv_val}" = "<unset>" ]; then
      printf "  %-20s : <unset>\n" "${_plv_name}" >&2
      return
    fi

    _plv_count=0
    _plv_dupes=0
    _plv_seen=""
    _plv_lines="$(mktemp)"
    _plv_dupe_names="$(mktemp)"
    _plv_old_ifs="${IFS}"

    #? The enumerated list below stays in original order on purpose --
    #? for PATH/DOTS_PATH that order IS command-lookup precedence, and
    #? for XDG_DATA_DIRS it's XDG search precedence, so sorting it would
    #? hide the exact thing this dump exists to show. Duplicate *names*
    #? are collected separately and reported sorted+deduped afterward,
    #? which gives a quick "what repeats" scan without reordering the
    #? real list.
    IFS=:
    for _plv_entry in ${_plv_val}; do
      IFS="${_plv_old_ifs}"
      _plv_count=$((_plv_count + 1))
      case " ${_plv_seen} " in
      *" ${_plv_entry} "*)
        _plv_dupes=$((_plv_dupes + 1))
        printf '%s\n' "${_plv_entry}" >>"${_plv_dupe_names}"
        printf "    [%3d] %-60s (duplicate)\n" "${_plv_count}" "${_plv_entry}" >>"${_plv_lines}"
        ;;
      *)
        _plv_seen="${_plv_seen} ${_plv_entry}"
        printf "    [%3d] %s\n" "${_plv_count}" "${_plv_entry}" >>"${_plv_lines}"
        ;;
      esac
      IFS=:
    done
    IFS="${_plv_old_ifs}"

    if [ "${_plv_dupes}" -gt 0 ]; then
      printf "  %-20s : (%d entries, %d duplicate)\n" "${_plv_name}" "${_plv_count}" "${_plv_dupes}" >&2
    else
      printf "  %-20s : (%d entries)\n" "${_plv_name}" "${_plv_count}" >&2
    fi
    cat "${_plv_lines}" >&2

    if [ "${_plv_dupes}" -gt 0 ]; then
      printf "           duplicated: " >&2
      sort -u "${_plv_dupe_names}" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g' >&2
      printf "\n" >&2
    fi

    rm -f "${_plv_lines}" "${_plv_dupe_names}"
    unset _plv_name _plv_val _plv_count _plv_dupes _plv_seen _plv_lines _plv_dupe_names _plv_old_ifs _plv_entry
  }

  # Export & display environment state for a specific stage
  export_stage_debug() {
    _stage_title="$1"
    shift

    printf "========================================================================\n" >&2
    printf " STAGE DEBUG DUMP: %s\n" "${_stage_title}" >&2
    printf "========================================================================\n" >&2

    for _var in "$@"; do
      eval "_val=\${${_var}:-<unset>}"
      case "${_var}" in
      PATH | XDG_DATA_DIRS | DOTS_PATH) print_list_var "${_var}" "${_val}" ;;
      *) printf "  %-20s : %s\n" "${_var}" "${_val}" >&2 ;;
      esac
    done
    echo "------------------------------------------------------------------------" >&2
  }

  #| Prints every exported variable, grouped by the module that set
  #? it. With no args, dumps every known group plus a catch-all
  #? "Other Exported" group for anything exported that isn't in one of
  #? the curated lists below -- so this never silently misses a
  #? variable just because a group list wasn't updated. Pass one or
  #? more of: environment, xdg, system, binary -- to scope the dump to
  #? just those groups (used internally by --debug-env/--debug-bin so
  #? those flags don't dump modules that haven't run yet).
  dump_stage_vars() {
    _dsv_wanted="$*"
    _dsv_seen=""

    _dsv_want() {
      [ -z "${_dsv_wanted}" ] && return 0
      case " ${_dsv_wanted} " in *" $1 "*) return 0 ;; *) return 1 ;; esac
    }

    if _dsv_want environment; then
      # shellcheck disable=SC2086
      export_stage_debug "Environment (init_env)" ${DOTS_VARS_ENV}
      _dsv_seen="${_dsv_seen} ${DOTS_VARS_ENV}"
    fi
    if _dsv_want xdg; then
      # shellcheck disable=SC2086
      export_stage_debug "XDG (init_env)" ${DOTS_VARS_XDG}
      _dsv_seen="${_dsv_seen} ${DOTS_VARS_XDG}"
    fi
    if _dsv_want system; then
      # shellcheck disable=SC2086
      export_stage_debug "System Defaults (init_env)" ${DOTS_VARS_SYS}
      _dsv_seen="${_dsv_seen} ${DOTS_VARS_SYS}"
    fi
    if _dsv_want binary; then
      # shellcheck disable=SC2086
      export_stage_debug "Binary Indexing (init_bin)" ${DOTS_VARS_BIN}
      _dsv_seen="${_dsv_seen} ${DOTS_VARS_BIN}"
    fi

    if [ -z "${_dsv_wanted}" ]; then
      #? Anything exported but not in one of the groups above still
      #? shows up here. Common shell-internal noise is filtered out so
      #? this stays readable.
      _dsv_skip=" PWD OLDPWD SHLVL _ PS1 PS2 PS4 IFS OPTIND SECONDS RANDOM LINENO SHELL TERM BASH BASH_VERSION ZSH_VERSION "
      _dsv_other=""
      for _name in $(env | cut -d= -f1 | sort -u); do
        case " ${_dsv_seen} " in *" ${_name} "*) continue ;; *) ;; esac
        case "${_dsv_skip}" in *" ${_name} "*) continue ;; *) ;; esac
        case "${_name}" in _dsv_*) continue ;; *) ;; esac
        _dsv_other="${_dsv_other} ${_name}"
      done
      if [ -n "${_dsv_other}" ]; then
        # shellcheck disable=SC2086
        export_stage_debug "Other Exported" ${_dsv_other}
      fi
    fi
  }

  #| Full read-only audit of the binary-indexing stage: which files
  #? would be (or already are) made executable, which directories
  #? would be (or already are) added to PATH, the active ignore rules,
  #? and any bin-name collisions. Does its own discovery pass (one
  #? tree walk, same as a real binit run) but never chmod's anything
  #? or touches PATH.
  dump_stage_bins() {
    require_binit_targets || return 1

    _file_list="$(mktemp)"
    _tier=$(time_stage "discover" list_shebang_candidates "${_file_list}")

    printf "========================================================================\n" >&2
    printf " STAGE DUMP: Binary Audit (dump_stage_bins)\n" >&2
    printf "========================================================================\n" >&2
    printf "  Indexed targets: %s\n" "${DOTS_BINIT_TARGETS}" >&2
    printf "  Discovery tier : %s\n\n" "${_tier}" >&2

    printf -- "-- Executables ---------------------------------------------------------\n" >&2
    _exec_count=0
    _pending_count=0
    _skip_count=0

    while IFS= read -r file; do
      [ -n "${file}" ] || continue

      ext="${file##*.}"
      case " ${DOTS_BINIT_BLACKLIST_EXT} " in
      *" ${ext} "*)
        printf "  [skip: .%s]     %s\n" "${ext}" "${file}" >&2
        _skip_count=$((_skip_count + 1))
        continue
        ;;
      *) ;;
      esac

      if [ -x "${file}" ]; then
        printf "  [x]             %s\n" "${file}" >&2
        _exec_count=$((_exec_count + 1))
      elif [ "${_tier}" = "rg" ]; then
        printf "  [pending chmod] %s\n" "${file}" >&2
        _pending_count=$((_pending_count + 1))
      else
        IFS= read -r first_line <"${file}" 2>/dev/null
        case "${first_line}" in
        "#!"*)
          printf "  [pending chmod] %s\n" "${file}" >&2
          _pending_count=$((_pending_count + 1))
          ;;
        *) ;;
        esac
      fi
    done <"${_file_list}"

    printf "\n  Summary: %d executable, %d pending chmod, %d skipped (blacklisted extension)\n\n" \
      "${_exec_count}" "${_pending_count}" "${_skip_count}" >&2

    printf -- "-- Path Additions -------------------------------------------------------\n" >&2
    _existing_count=0
    _new_count=0
    _dirs_seen=""
    while IFS= read -r file; do
      [ -n "${file}" ] || continue
      ext="${file##*.}"
      case " ${DOTS_BINIT_BLACKLIST_EXT} " in *" ${ext} "*) continue ;; *) ;; esac
      dir="${file%/*}"
      [ -n "${dir}" ] || continue
      case " ${_dirs_seen} " in *" ${dir} "*) continue ;; *) ;; esac
      _dirs_seen="${_dirs_seen} ${dir}"
      case ":${PATH}:" in
      *:"${dir}":*)
        printf "  [on PATH]   %s\n" "${dir}" >&2
        _existing_count=$((_existing_count + 1))
        ;;
      *)
        printf "  [would add] %s\n" "${dir}" >&2
        _new_count=$((_new_count + 1))
        ;;
      esac
    done <"${_file_list}"
    printf "\n  Summary: %d already on PATH, %d would be added\n\n" "${_existing_count}" "${_new_count}" >&2

    printf -- "-- Ignore Rules ----------------------------------------------------------\n" >&2
    printf "  Directories (DOTS_BINIT_IGNORE)     : %s\n" "${DOTS_BINIT_IGNORE}" >&2
    printf "  Directories (always ignored) : .git .jj .hg .svn node_modules\n" >&2
    printf "  Extensions (DOTS_BINIT_BLACKLIST_EXT)   : %s\n" "${DOTS_BINIT_BLACKLIST_EXT}" >&2
    printf "  (files under ignored directories are excluded before the scan sees\n" >&2
    printf "   them, so they can't be listed individually here without a second,\n" >&2
    printf "   slower unfiltered pass)\n\n" >&2

    printf -- "-- Collisions --------------------------------------------------------------\n" >&2
    _dump_names="$(mktemp)"
    while IFS= read -r file; do
      [ -n "${file}" ] || continue
      ext="${file##*.}"
      case " ${DOTS_BINIT_BLACKLIST_EXT} " in *" ${ext} "*) continue ;; *) ;; esac
      printf "%s\t%s\n" "${file##*/}" "${file}" >>"${_dump_names}"
    done <"${_file_list}"
    if check_bin_collisions "${_dump_names}"; then
      printf "  none found\n" >&2
    fi
    rm -f "${_dump_names}"

    rm -f "${_file_list}"
  }
}

# ── Main Entrypoint & CLI Parsing ────────────────────────────────────────────

#| No argument parsing -- this file is `.`-sourced, so every switch is
#? read straight from the environment (see binit()'s doc comment
#? for the full list). Set what you need before sourcing, e.g.:
#?   DEBUG_DOTS_BIN=1 DEBUG_DOTS_ENV=1 . "${DOTS_BINIT}"
main() {
  init_diagnostics

  time_stage "init_lib" init_lib
  time_stage "init_env" init_env

  if is_truthy "${DOTS_BINIT_SKIP:-0}"; then
    if is_truthy "${DEBUG_DOTS_BIN:-0}"; then
      printf "dots: [STAGE SKIPPED] init_bin was bypassed via DOTS_BINIT_SKIP\n" >&2
    fi
    return 0
  fi

  #? Guards against redoing the full tree-walk + chmod + PATH-build in
  #? every subshell that already inherited a correctly-built PATH from
  #? a parent shell (e.g. this file wired into an RC that gets sourced
  #? repeatedly -- tmux panes, nested shells, `direnv reload`, etc). The
  #? marker is exported so children see it; DOTS_BINIT_FORCE=1 bypasses
  #? the guard when you actually need a fresh scan (new script added,
  #? permissions changed).
  if is_truthy "${DOTS_BINIT_DONE:-0}" && ! is_truthy "${DOTS_BINIT_FORCE:-0}"; then
    if is_truthy "${DEBUG_DOTS_BIN:-0}"; then
      printf "dots: [STAGE SKIPPED] init_bin already completed in this environment (DOTS_BINIT_DONE=1) -- set DOTS_BINIT_FORCE=1 to re-run\n" >&2
    fi
    return 0
  fi

  time_stage "init_bin" init_bin
  DOTS_BINIT_DONE=1
  export DOTS_BINIT_DONE
}

main
