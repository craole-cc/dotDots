# Fish Shell Environment Configuration

#@ Define top-level paths
set -gx DOTS_BIN (test -n "$DOTS_BIN"; and echo "$DOTS_BIN"; or echo "$DOTS/Bin")
set -gx DOTS_CFG (test -n "$DOTS_CFG"; and echo "$DOTS_CFG"; or echo "$DOTS/Configuration")
set -gx DOTS_DLD (test -n "$DOTS_DLD"; and echo "$DOTS_DLD"; or echo "$DOTS/Import")
set -gx DOTS_ENV (test -n "$DOTS_ENV"; and echo "$DOTS_ENV"; or echo "$DOTS/Environment")
set -gx DOTS_MOD (test -n "$DOTS_MOD"; and echo "$DOTS_MOD"; or echo "$DOTS/Modules")

#@ Define excluded folder patterns
set -gx DOTS_EXCLUDE_PATTERNS 'review|tmp|temp|archive|backup'

#@ Define sub-paths
set -gx DOTS_ENV_CONTEXT (test -n "$DOTS_ENV_CONTEXT"; and echo "$DOTS_ENV_CONTEXT"; or echo "$DOTS_ENV/context")
set -gx DOTS_ENV_EXPORT (test -n "$DOTS_ENV_EXPORT"; and echo "$DOTS_ENV_EXPORT"; or echo "$DOTS_ENV/export")
set -gx DOTS_ENV_IMPORT (test -n "$DOTS_ENV_IMPORT"; and echo "$DOTS_ENV_IMPORT"; or echo "$DOTS_ENV/export")
set -gx DOTS_ENV_BASE (test -n "$DOTS_ENV_BASE"; and echo "$DOTS_ENV_BASE"; or echo "$DOTS_ENV_EXPORT/base")
set -gx DOTS_ENV_CORE (test -n "$DOTS_ENV_CORE"; and echo "$DOTS_ENV_CORE"; or echo "$DOTS_ENV_EXPORT/core")
set -gx DOTS_ENV_UTIL (test -n "$DOTS_ENV_UTIL"; and echo "$DOTS_ENV_UTIL"; or echo "$DOTS_ENV_EXPORT/utility")
set -gx DOTS_ENV_PKGS (test -n "$DOTS_ENV_PKGS"; and echo "$DOTS_ENV_PKGS"; or echo "$DOTS_ENV_EXPORT/package")
set -gx DOTS_ENV_PRJ (test -n "$DOTS_ENV_PRJ"; and echo "$DOTS_ENV_PRJ"; or echo "$DOTS_ENV/export/project")

#@ Launch shell-specific configuration
set shell_name "fish"
set shell_rc "$DOTS_CFG/fish/config.fish"

#@ Load shell-specific configuration
if test -f "$shell_rc"
    # source "$shell_rc"
    printf "INFO >>= DOTS Shell =<< Initialized '%s' using '%s'\n" "$shell_name" "$shell_rc"
else
    printf "WARN >>= DOTS Shell =<< Missing configuration file for %s: '%s'\n" "$shell_name" "$shell_rc" >&2
end