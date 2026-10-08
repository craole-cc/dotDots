#!/bin/sh
# shflint_test.sh – end-to-end tests for shflint (plain POSIX sh, no framework)
#
# Usage:
#   shflint_test.sh [-v] [-k PATTERN] [path/to/shflint]
#
#   -v           show the output of passing tests too
#   -k PATTERN   only run tests whose name contains PATTERN
#
# shflint is located via (first hit wins): the positional argument, $SHFLINT,
# ../../Libraries/posix/project/formatters/shflint relative to this file,
# then `shflint` on PATH.
#
# Every test runs in its own scratch directory with a private HOME, so your
# personal ~/.shellcheckrc or ~/.editorconfig can't change the results.
#
# Needs: shellcheck, shfmt, patch (the same things shflint needs).

# Fixtures and expected strings are full of literal ${...} in single quotes.
# shellcheck disable=SC2016

set -u

#~@ Runner state
HERE=$(cd "$(dirname -- "$0")" && pwd)
VERBOSE=0
PATTERN=""
SHFLINT="${SHFLINT:-}"
WORK=""
PASSED=0
FAILED=0
FAILED_NAMES=""

OUT=""
RC=0

#~@ Setup
cleanup() {
  if [ -n "${WORK}" ] && [ -d "${WORK}" ]; then
    rm -rf "${WORK}"
  fi
}

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

locate_shflint() {
  if [ -z "${SHFLINT}" ]; then
    _guess="${HERE}/../../Libraries/posix/project/formatters/shflint"
    if [ -f "${_guess}" ]; then
      SHFLINT="${_guess}"
    elif command -v shflint > /dev/null 2>&1; then
      SHFLINT=$(command -v shflint)
    fi
  fi
  if [ -z "${SHFLINT}" ] || [ ! -f "${SHFLINT}" ]; then
    printf 'shflint_test: cannot find shflint (pass a path or set SHFLINT)\n' >&2
    exit 2
  fi
  SHFLINT="$(cd "$(dirname -- "${SHFLINT}")" && pwd)/$(basename -- "${SHFLINT}")"
  [ -x "${SHFLINT}" ] || chmod +x "${SHFLINT}" 2> /dev/null || true
}

check_deps() {
  for _tool in shellcheck shfmt patch cksum; do
    if ! command -v "${_tool}" > /dev/null 2>&1; then
      printf 'shflint_test: missing required tool: %s\n' "${_tool}" >&2
      exit 2
    fi
  done
}

#~@ Helpers available to tests
# run_lint ARGS... – run shflint, capture combined output in $OUT and status in $RC
run_lint() {
  OUT=$("${SHFLINT}" "$@" 2>&1)
  RC=$?
}

# write_file PATH – fixture from stdin (creates parent dirs)
write_file() {
  mkdir -p "$(dirname -- "$1")"
  cat > "$1"
}

# A tiny hermetic ShellCheck config: braces are required (SC2250) like in the real repo
write_rc() {
  printf 'enable=require-variable-braces\n' > .shellcheckrc
}

fail() {
  printf '    FAIL: %s\n' "$*"
  if [ -n "${OUT}" ]; then
    printf '    ---- last shflint output (rc=%s) ----\n' "${RC}"
    printf '%s\n' "${OUT}" | sed 's/^/    | /'
  fi
  exit 1
}

assert_rc() {
  [ "${RC}" -eq "$1" ] || fail "expected exit status $1, got ${RC}"
}

# assert_has FILE TEXT – fixed-string match
assert_has() {
  grep -F -q -- "$2" "$1" || {
    printf '    ---- %s ----\n' "$1"
    sed 's/^/    | /' "$1"
    fail "expected $1 to contain: $2"
  }
}

assert_lacks() {
  if grep -F -q -- "$2" "$1"; then
    printf '    ---- %s ----\n' "$1"
    sed 's/^/    | /' "$1"
    fail "expected $1 NOT to contain: $2"
  fi
}

assert_out_has() {
  printf '%s\n' "${OUT}" | grep -F -q -- "$1" || fail "expected output to contain: $1"
}

assert_out_lacks() {
  if printf '%s\n' "${OUT}" | grep -F -q -- "$1"; then
    fail "expected output NOT to contain: $1"
  fi
}

assert_same() {
  [ "$(cksum < "$1")" = "$(cksum < "$2")" ] || fail "expected $1 and $2 to be identical"
}

# Scratch files from shflint must never be left behind
assert_no_scratch() {
  _left=$(find "$1" \( -name 'shflint-tmp.*' -o -name '*.sedtmp' -o -name '*.orig' -o -name '*.rej' \) 2> /dev/null)
  [ -z "${_left}" ] || fail "scratch files left behind: ${_left}"
}

#~@ Tests: the actual autofix (the thing that regressed)
test_autofix_quotes_and_braces() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
name=$(printf x)
echo $name
EOF
  run_lint "${PWD}/a.sh"
  assert_rc 0
  assert_has a.sh 'echo "${name}"'
}

test_autofix_works_with_absolute_and_relative_paths() {
  write_rc
  write_file abs.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  cp abs.sh rel.sh
  run_lint "${PWD}/abs.sh"
  assert_has abs.sh 'cd /tmp || exit'
  run_lint rel.sh
  assert_has rel.sh 'cd /tmp || exit'
  mkdir sub
  cp abs.sh sub/rel2.sh
  run_lint sub/rel2.sh
  assert_has sub/rel2.sh 'cd /tmp || exit'
}

test_autofix_cd_or_exit() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  run_lint a.sh
  assert_rc 0
  assert_has a.sh 'cd /tmp || exit'
}

test_autofix_posix_double_equals() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
name=$(printf x)
[ "${name}" == "x" ] && echo match
EOF
  run_lint a.sh
  assert_rc 0
  assert_has a.sh '[ "${name}" = "x" ]'
  assert_lacks a.sh '=='
}

test_autofix_test_dash_a() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
a=$(printf 1)
b=$(printf 2)
if [ -n "${a}" -a -n "${b}" ]; then
  echo both
fi
EOF
  run_lint a.sh
  assert_rc 0
  assert_has a.sh 'if [ -n "${a}" ] && [ -n "${b}" ]; then'
}

test_autofix_test_dash_o() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
a=$(printf 1)
b=$(printf 2)
if [ -n "${a}" -o -n "${b}" ]; then
  echo either
fi
EOF
  run_lint a.sh
  assert_rc 0
  assert_has a.sh 'if [ -n "${a}" ] || [ -n "${b}" ]; then'
}

test_autofix_leaves_mixed_a_and_o_alone() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
a=$(printf 1)
b=$(printf 2)
c=$(printf 3)
if [ -n "${a}" -a -n "${b}" -o -n "${c}" ]; then
  echo ambiguous
fi
EOF
  run_lint a.sh
  # Splitting this would change its meaning, so it must be reported, not rewritten
  assert_rc 1
  assert_has a.sh '-n "${a}" -a -n "${b}" -o -n "${c}"'
  assert_out_has 'SC2166'
}

test_autofix_multiple_issues_in_one_file() {
  write_rc
  write_file fmt.sh << 'EOF'
#!/bin/sh
name=$(printf x)
files=$(printf y)

echo $name
[ $name == "x" ] && echo "match"

cd /tmp
if [ -n "$name" -a -n "$files" ]; then
  echo "$name"
fi
EOF
  run_lint "${PWD}/fmt.sh"
  assert_rc 0
  assert_has fmt.sh 'echo "${name}"'
  assert_has fmt.sh '[ "${name}" = "x" ] && echo "match"'
  assert_has fmt.sh 'cd /tmp || exit'
  assert_has fmt.sh 'if [ -n "${name}" ] && [ -n "${files}" ]; then'
}

#~@ Tests: formatting
test_format_default_indent_is_two() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
if true;then
echo hi
fi
EOF
  run_lint a.sh
  assert_rc 0
  assert_has a.sh '  echo hi'
  assert_has a.sh 'if true; then'
}

test_format_custom_indent() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
if true;then
echo hi
fi
EOF
  run_lint -i 4 a.sh
  assert_rc 0
  assert_has a.sh '    echo hi'
  run_lint --indent 4 a.sh
  assert_rc 0
}

test_format_case_indent() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
case $1 in
a) echo a;;
esac
EOF
  run_lint a.sh
  assert_has a.sh '  a) echo a ;;'
}

#~@ Tests: behaviour
test_idempotent() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
name=$(printf x)
cd /tmp
echo $name
[ $name == x ] && echo hi
EOF
  run_lint a.sh
  cp a.sh first.sh
  run_lint a.sh
  assert_rc 0
  assert_out_lacks 'fixed'
  assert_same a.sh first.sh
}

test_clean_file_exits_zero_and_is_untouched() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
printf '%s\n' "hello"
EOF
  cp a.sh before.sh
  run_lint a.sh
  assert_rc 0
  assert_same a.sh before.sh
}

test_unfixable_issue_is_reported_with_exit_1_but_other_fixes_still_land() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
unused_value=1
cd /tmp
EOF
  run_lint a.sh
  assert_rc 1
  assert_out_has 'SC2034'
  assert_has a.sh 'cd /tmp || exit'
}

test_preserves_executable_bit() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  chmod 755 a.sh
  run_lint a.sh
  [ -x a.sh ] || fail "executable bit was lost"
}

test_preserves_utf8() {
  _loc=""
  for _l in C.UTF-8 C.utf8 en_US.UTF-8; do
    if locale -a 2> /dev/null | grep -q -x -F "${_l}"; then
      _loc=${_l}
      break
    fi
  done
  [ -n "${_loc}" ] || return 0 # no UTF-8 locale on this box; nothing to check

  write_rc
  # "café à" as raw bytes: 0xC3 0xA9 and 0xC3 0xA0 (0xA0 is what an old `tr '\240'` would corrupt)
  {
    printf '#!/bin/sh\nv=$(printf 1)\n'
    printf 'echo "caf\303\251 \303\240 $v"\n'
  } > a.sh
  OUT=$(LC_ALL=${_loc} "${SHFLINT}" a.sh 2>&1)
  RC=$?
  assert_rc 0
  assert_has a.sh "$(printf 'caf\303\251 \303\240 ${v}')"
}

test_formats_extensionless_scripts() {
  write_rc
  write_file myscript << 'EOF'
#!/bin/sh
if true;then
echo hi
fi
EOF
  run_lint myscript
  assert_rc 0
  assert_has myscript '  echo hi'
}

test_formats_scripts_with_unusual_extension() {
  write_rc
  write_file thing.bash << 'EOF'
if true;then
echo hi
fi
EOF
  run_lint thing.bash
  assert_has thing.bash '  echo hi'
}

test_no_scratch_files_left_behind() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
cd /tmp
unused=1
EOF
  run_lint a.sh
  assert_no_scratch .
}

test_unparsable_file_is_reported_and_left_alone() {
  write_rc
  write_file bad.sh << 'EOF'
#!/bin/sh
if then
EOF
  cp bad.sh before.sh
  run_lint bad.sh
  assert_rc 1
  assert_same bad.sh before.sh
  assert_out_has 'could not be parsed'
  assert_no_scratch .
}

test_file_with_spaces_in_name() {
  write_rc
  write_file "my script.sh" << 'EOF'
#!/bin/sh
cd /tmp
EOF
  run_lint "${PWD}/my script.sh"
  assert_rc 0
  assert_has "my script.sh" 'cd /tmp || exit'
}

test_multiple_file_arguments_continue_after_failure() {
  write_rc
  write_file one.sh << 'EOF'
#!/bin/sh
unused=1
EOF
  write_file two.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  run_lint one.sh two.sh
  assert_rc 1
  assert_has two.sh 'cd /tmp || exit'
}

#~@ Tests: dry run
test_dry_run_does_not_modify_and_shows_diff() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  cp a.sh before.sh
  run_lint -d a.sh
  assert_rc 1
  assert_same a.sh before.sh
  assert_out_has '+cd /tmp || exit'
  assert_no_scratch .
}

test_dry_run_on_clean_file_exits_zero() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
printf '%s\n' ok
EOF
  run_lint --dry-run a.sh
  assert_rc 0
}

test_dry_run_lists_issues_that_would_remain() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
unused=1
EOF
  run_lint -d a.sh
  assert_rc 1
  assert_out_has 'SC2034'
  assert_out_has 'a.sh'
}

#~@ Tests: --guard-vars (opt-in)
test_guard_vars_is_off_by_default() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
echo "$missing_var"
EOF
  run_lint a.sh
  assert_lacks a.sh ':?}'
}

test_guard_vars_rewrites_unassigned_variables() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
echo "$missing_var" ${missing_var}
printf '%s\n' "x$missing_var"
EOF
  run_lint -g a.sh
  assert_has a.sh '"${missing_var:?}"'
  assert_has a.sh '"x${missing_var:?}"'
  assert_lacks a.sh '\1'
}

test_guard_vars_does_not_touch_similar_names() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
missing_var_two=$(printf 1)
echo "${missing_var_two}" "$missing_var"
EOF
  run_lint -g a.sh
  assert_has a.sh '"${missing_var_two}"'
  assert_has a.sh '"${missing_var:?}"'
}

#~@ Tests: directory mode
test_directory_mode_fixes_shell_files_only() {
  write_rc
  write_file tree/a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  write_file tree/sub/noext << 'EOF'
#!/usr/bin/env bash
cd /tmp
EOF
  write_file "tree/with space/b.bash" << 'EOF'
cd /tmp
EOF
  printf 'cd /tmp\n' > tree/notes.txt
  printf '# docs\n\n    cd /tmp\n' > tree/README.md
  printf '#!/usr/bin/env python3\nprint("cd /tmp")\n' > tree/tool.py
  cp tree/notes.txt notes.before
  cp tree/README.md readme.before
  cp tree/tool.py tool.before

  run_lint tree
  assert_has tree/a.sh 'cd /tmp || exit'
  assert_has tree/sub/noext 'cd /tmp || exit'
  assert_has "tree/with space/b.bash" 'cd /tmp || exit'
  assert_same tree/notes.txt notes.before
  assert_same tree/README.md readme.before
  assert_same tree/tool.py tool.before
  assert_no_scratch tree
}

test_directory_mode_continues_after_unfixable_file() {
  write_rc
  # "aaa" sorts first; it has an issue ShellCheck can't autofix
  write_file tree/aaa.sh << 'EOF'
#!/bin/sh
unused=1
EOF
  write_file tree/zzz.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  run_lint tree
  assert_rc 1
  assert_has tree/zzz.sh 'cd /tmp || exit'
}

test_directory_mode_many_files_in_parallel() {
  write_rc
  mkdir tree
  _i=0
  while [ "${_i}" -lt 60 ]; do
    printf '#!/bin/sh\ncd /tmp\n' > "$(printf 'tree/f%02d.sh' "${_i}")"
    _i=$((_i + 1))
  done
  run_lint tree
  assert_rc 0
  _unfixed=$(grep -L -F 'cd /tmp || exit' tree/*.sh)
  [ -z "${_unfixed}" ] || fail "files not fixed: ${_unfixed}"
  assert_no_scratch tree
}

test_directory_dry_run_changes_nothing() {
  write_rc
  write_file tree/a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  cp tree/a.sh before.sh
  run_lint -d tree
  assert_rc 1
  assert_same tree/a.sh before.sh
  assert_no_scratch tree
}

test_directory_mode_without_fd_uses_find() {
  write_rc
  write_file tree/a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  # Hide fd/fdfind by building a PATH of symlinks to everything except them
  mkdir -p nofd
  for _dir in $(printf '%s' "${PATH}" | tr ':' ' '); do
    for _bin in "${_dir}"/*; do
      _name=${_bin##*/}
      case ${_name} in fd | fdfind) continue ;; *) ;; esac
      [ -e "nofd/${_name}" ] || ln -s "${_bin}" "nofd/${_name}" 2> /dev/null
    done
  done
  OUT=$(PATH="${PWD}/nofd" "${SHFLINT}" tree 2>&1)
  RC=$?
  assert_rc 0
  assert_has tree/a.sh 'cd /tmp || exit'
}

#~@ Tests: CLI contract
test_help_exits_zero() {
  run_lint -h
  assert_rc 0
  assert_out_has 'Usage'
  run_lint --help
  assert_rc 0
}

test_no_arguments_is_a_usage_error() {
  run_lint
  assert_rc 2
  assert_out_has 'Usage'
}

test_unknown_option_is_a_usage_error() {
  run_lint --nope a.sh
  assert_rc 2
  assert_out_has 'unknown option'
}

test_non_numeric_indent_is_a_usage_error() {
  write_file a.sh << 'EOF'
#!/bin/sh
true
EOF
  run_lint -i abc a.sh
  assert_rc 2
  run_lint -i
  assert_rc 2
}

test_missing_path_is_reported_and_fails() {
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  run_lint does-not-exist.sh a.sh
  assert_rc 1
  assert_out_has 'non-existent'
  # ...but the valid file after it is still processed
  assert_has a.sh 'cd /tmp || exit'
}

test_runs_under_a_strict_posix_shell() {
  command -v dash > /dev/null 2>&1 || return 0
  write_rc
  write_file a.sh << 'EOF'
#!/bin/sh
cd /tmp
EOF
  OUT=$(dash "${SHFLINT}" a.sh 2>&1)
  RC=$?
  assert_rc 0
  assert_has a.sh 'cd /tmp || exit'
}

test_shflint_lints_itself_cleanly() {
  write_rc
  cp "${SHFLINT}" self.sh
  # Our own source must already be a fixed point of the tool, with nothing left to report
  run_lint self.sh
  assert_rc 0
  assert_out_lacks 'fixed'
}

#~@ Runner
run_test() {
  _rt_name=$1
  _rt_dir="${WORK}/${_rt_name}"
  mkdir -p "${_rt_dir}/home/.config"

  _rt_out=$(
    cd "${_rt_dir}" || exit 1
    export HOME="${_rt_dir}/home"
    export XDG_CONFIG_HOME="${HOME}/.config"
    export NO_COLOR=1
    unset SHELLCHECK_OPTS
    OUT=""
    RC=0
    "${_rt_name}"
  )
  _rt_rc=$?

  if [ "${_rt_rc}" -eq 0 ]; then
    PASSED=$((PASSED + 1))
    printf 'ok      %s\n' "${_rt_name}"
    if [ "${VERBOSE}" -eq 1 ] && [ -n "${_rt_out}" ]; then
      printf '%s\n' "${_rt_out}" | sed 's/^/    | /'
    fi
  else
    FAILED=$((FAILED + 1))
    FAILED_NAMES="${FAILED_NAMES} ${_rt_name}"
    printf 'FAILED  %s\n' "${_rt_name}"
    [ -z "${_rt_out}" ] || printf '%s\n' "${_rt_out}"
  fi
}

main() {
  while [ $# -gt 0 ]; do
    case $1 in
      -v) VERBOSE=1 ;;
      -k)
        [ $# -ge 2 ] || {
          usage >&2
          exit 2
        }
        PATTERN=$2
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -*)
        usage >&2
        exit 2
        ;;
      *) SHFLINT=$1 ;;
    esac
    shift
  done

  locate_shflint
  check_deps

  WORK=$(mktemp -d "${TMPDIR:-/tmp}/shflint_test.XXXXXX") || exit 2
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP

  printf 'shflint:    %s\n' "${SHFLINT}"
  printf 'shellcheck: %s\n' "$(shellcheck --version | sed -n 's/^version: //p')"
  printf 'shfmt:      %s\n\n' "$(shfmt --version)"

  # shellcheck disable=SC2013
  for _name in $(sed -n 's/^\(test_[A-Za-z0-9_]*\)().*/\1/p' "$0"); do
    case ${_name} in *"${PATTERN}"*) ;; *) continue ;; esac
    run_test "${_name}"
  done

  printf '\n%s passed, %s failed\n' "${PASSED}" "${FAILED}"
  if [ "${FAILED}" -ne 0 ]; then
    printf 'failed:%s\n' "${FAILED_NAMES}"
    exit 1
  fi
}

main "$@"
