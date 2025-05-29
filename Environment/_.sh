#!/bin/sh
# shellcheck enable=all
# shellcheck disable=SC1090

#@ Set defaults
debug=
init_time="$(date +%s%3N)"

#@ Define debugging functions
pout_with_tag() {
  [ -z "${debug:-}" ] && return
  msg=""
  tag="DEBUG"
  ctx="DOTS"
  while [ "$#" -gt 0 ]; do
    case "$1" in
    -t | --tag)
      tag="$2"
      shift
      ;;
    -c | --ctx)
      ctx="${ctx:+"${ctx}"|}$2"
      shift
      ;;
    *) msg="${msg:+"${msg}" }$1" ;;
    esac
    shift
  done

  printf "%s >>= %s =<< %s\n" "${tag}" "${ctx}" "${msg}"
}

pout_env() {
  [ -z "${debug:-}" ] && return
  var="$1"
  eval "val=\$${var}"
  printf "%s => %s\n" "${var:?}" "${val:-}"
}

#@ Define required paths
DOTS_CFG="${DOTS_CFG:-"${DOTS}/Configuration"}" export DOTS_CFG
DOTS_ENV="${DOTS_ENV:-"${DOTS}/Environment"}" export DOTS_ENV
DOTS_ENV_POSIX="${DOTS_ENV_POSIX:-"${DOTS_ENV}/posix"}" export DOTS_ENV_POSIX
DOTS_ENV_POSIX_EXPORT="${DOTS_ENV_POSIX_EXPORT:-"${DOTS_ENV_POSIX}/export"}" export DOTS_ENV_POSIX_EXPORT

#@ Define folder patterns to exclude
DOTS_EXCLUDE_PATTERNS='review|tmp|temp|archive|backup|template' export DOTS_EXCLUDE_PATTERNS

#@ Identify environment files to load
DELIMITER="$(printf "\037")"
ifs=${IFS}
envs=$(
  find "${DOTS_ENV_POSIX_EXPORT}" -type f |
    while IFS= read -r file; do
      case "${file}" in
      *template* | *review* | *tmp* | *temp* | *archive* | *backup*) continue ;;
      *) printf '%s%s' "${file}" "${DELIMITER}" ;;
      esac
    done
)

#@ Load environment files (excluding patterns)
count=0
IFS="${DELIMITER}"
for file in ${envs}; do
  [ -z "${file}" ] && continue
  count=$((count + 1))
  pout_with_tag  --tag "INFO " --ctx "ENV" "$(printf "%4d. %s\n" "${count}" "${file}")"
  . "${file}"
done
IFS="${ifs}"

#@ Launch shell-specific configuration
if [ -n "${BASH_VERSION:-}" ]; then
  SHELL_NAME="Bourne Again SHell"
  SHELL_TAG="bash"
elif [ -n "${ZSH_VERSION:-}" ]; then
  SHELL_NAME="Z Shell"
  SHELL_TAG="zsh"
fi

#@ Load shell-specific configuration
SHELL_HOME="${DOTS_CFG}/${SHELL_TAG}" export SHELL_HOME
SHELL_RC="${SHELL_HOME}/config.${SHELL_TAG}" export SHELL_RC
if [ -f "${SHELL_RC}" ]; then
  pout_with_tag --tag "TRACE" --ctx "${SHELL_TAG}" \
    "Attempting to launch the configuration for the" "${SHELL_NAME}"
  . "${SHELL_RC}"
  pout_with_tag --tag "INFO " --ctx "${SHELL_TAG}" \
    "Initialized the" "${SHELL_NAME}" "via" "${SHELL_RC}"
else
  pout_with_tag --tag "WARN " --ctx "${SHELL_TAG}" \
    "Missing configuration file for" "${SHELL_NAME}"
fi

IFS="${ifs}"

exit_time="$(date +%s%3N)"
printf "DOTS initialized (%sms)\n" "$((exit_time - init_time))"
