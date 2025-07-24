#! /bin/sh

#|->  Output Control
manage_env --set --var DELIMITER --val "${DELIMITER:-"$(printf "\037")"}"

echo "Verbosity: ${VERBOSITY:-"Not set"}"
manage_env --set --var VERBOSITY --val "$(verbosity "${VERBOSITY:-"Error"}" || true)"
manage_env --set --var VERBOSITY_QUIET --val "$(verbosity "${VERBOSITY_QUIET:-"Quiet"}" 0 || true)"
manage_env --set --var VERBOSITY_ERROR --val "$(verbosity "${VERBOSITY_ERROR:-"Error"}" 1 || true)"
manage_env --set --var VERBOSITY_WARN --val "$(verbosity "${VERBOSITY_WARN:-"Warn"}" 2 || true)"
manage_env --set --var VERBOSITY_INFO --val "$(verbosity "${VERBOSITY_INFO:-"Info"}" 3 || true)"
manage_env --set --var VERBOSITY_DEBUG --val "$(verbosity "${VERBOSITY_DEBUG:-"Debug"}" 4 || true)"
manage_env --set --var VERBOSITY_TRACE --val "$(verbosity "${VERBOSITY_TRACE:-"Trace"}" 5 || true)"
manage_env --set --var PAD --val "${PAD:-16}"
manage_env --set --var SEP --val "${SEP:-" | "}"
manage_env --set --var TIMESTAMP_FMT --val "%Y-%m-%d_%H-%M-%S"
