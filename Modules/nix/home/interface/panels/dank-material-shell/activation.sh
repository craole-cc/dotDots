#!/bin/sh
# Reconcile declared DMS settings and seed missing appearance files.
#
# Commands (unquoted on purpose, they may carry flags):
#   gum_log_info gum_log_error
#   jaq jaqn mkdirp dirname install0644 mktemp readlinkf cmps chmod0600 mvf rmf
# Paths:
#   settings plugins clipboard session hermes_skin
#   foot_theme foot_fallback
#   ghostty_opacity ghostty_opacity_fallback
#   kitty_opacity kitty_opacity_fallback
#   {settings,plugins,clipboard,session}_{overrides,defaults}
# Optional: dry_run_cmd

case "${dry_run_cmd}" in
"") ;;
*)
  ${gum_log_info} "Would reconcile declared DMS settings and seed missing appearance files"
  exit 0
  ;;
esac

for file in "${settings}" "${session}" "${foot_theme}" "${ghostty_opacity}" \
  "${kitty_opacity}" "${hermes_skin}"; do
  ${mkdirp} "$(${dirname} "${file}")" || exit 1
done

# seed_file SRC DST: install SRC at DST only if DST is absent (dangling symlinks count).
seed_file() {
  if [ -e "${2}" ] || [ -L "${2}" ]; then :; else
    if ${install0644} "${1}" "${2}"; then
      ${gum_log_info} "Seeded ${2}"
    else
      ${gum_log_error} "Failed to seed ${2}" >&2
      return 1
    fi
  fi
}

seed_file "${foot_fallback}" "${foot_theme}" || exit 1
seed_file "${ghostty_opacity_fallback}" "${ghostty_opacity}" || exit 1
seed_file "${kitty_opacity_fallback}" "${kitty_opacity}" || exit 1

# merge_json TARGET OVERRIDES DEFAULTS CREATE
# Subshell body: scoped variables without `local`, and `exit` acts as `return`.
merge_json() (
  target=${1} overrides=${2} defaults=${3} create=${4}

  if [ -e "${target}" ] || [ -L "${target}" ]; then :; else
    case "${create}" in
    true) ;;
    *) exit 0 ;;
    esac
  fi

  if [ -L "${target}" ]; then
    case "$(${readlinkf} "${target}")" in
    /nix/store/*) ;;
    *)
      ${gum_log_error} "Refusing to replace unmanaged DMS settings symlink: ${target}" >&2
      exit 1
      ;;
    esac
  fi

  if ! target_tmp="$(${mktemp} "${target}.tmp.XXXXXX")"; then
    ${gum_log_error} "Failed to create temporary file for ${target}" >&2
    exit 1
  fi

  if [ -f "${target}" ]; then
    if ! ${jaq} --slurpfile overrides "${overrides}" --slurpfile defaults "${defaults}" \
      '($defaults[0] * . * $overrides[0]) | if .currentThemeName == "dynamic" and ($overrides[0] | has("customThemeFile") | not) then .customThemeFile = $defaults[0].customThemeFile else . end' \
      "${target}" >"${target_tmp}"; then
      ${rmf} "${target_tmp}"
      ${gum_log_error} "Failed to merge DMS settings: ${target}" >&2
      exit 1
    fi
  else
    if ! ${jaqn} --slurpfile overrides "${overrides}" --slurpfile defaults "${defaults}" \
      '($defaults[0] * $overrides[0]) | if .currentThemeName == "dynamic" and ($overrides[0] | has("customThemeFile") | not) then .customThemeFile = $defaults[0].customThemeFile else . end' \
      >"${target_tmp}"; then
      ${rmf} "${target_tmp}"
      ${gum_log_error} "Failed to generate DMS settings: ${target}" >&2
      exit 1
    fi
  fi

  if ! ${cmps} "${target_tmp}" "${target}"; then
    ${chmod0600} "${target_tmp}"
    ${mvf} "${target_tmp}" "${target}"
    ${gum_log_info} "Updated ${target}"
  else
    ${rmf} "${target_tmp}"
  fi
)

#? API overrides win on each activation; unlisted values remain mutable in DMS.
merge_json "${settings}" "${settings_overrides}" "${settings_defaults}" true
merge_json "${plugins}" "${plugins_overrides}" "${plugins_defaults}" true
merge_json "${clipboard}" "${clipboard_overrides}" "${clipboard_defaults}" false
merge_json "${session}" "${session_overrides}" "${session_defaults}" true
