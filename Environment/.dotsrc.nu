# Nushell Environment Configuration

#{ Define top-level paths
$env.DOTS_BIN = ($env.DOTS_BIN? | default ($env.DOTS | path join "Bin"))
$env.DOTS_CFG = ($env.DOTS_CFG? | default ($env.DOTS | path join "Configuration"))
$env.DOTS_DLD = ($env.DOTS_DLD? | default ($env.DOTS | path join "Import"))
$env.DOTS_ENV = ($env.DOTS_ENV? | default ($env.DOTS | path join "Environment"))
$env.DOTS_MOD = ($env.DOTS_MOD? | default ($env.DOTS | path join "Modules"))

#{ Define excluded folder patterns
$env.DOTS_EXCLUDE_PATTERNS = "review|tmp|temp|archive|backup"

#{ Define sub-paths
$env.DOTS_ENV_CONTEXT = ($env.DOTS_ENV_CONTEXT? | default ($env.DOTS_ENV | path join "context"))
$env.DOTS_ENV_EXPORT = ($env.DOTS_ENV_EXPORT? | default ($env.DOTS_ENV | path join "export"))
$env.DOTS_ENV_IMPORT = ($env.DOTS_ENV_IMPORT? | default ($env.DOTS_ENV | path join "export"))
$env.DOTS_ENV_BASE = ($env.DOTS_ENV_BASE? | default ($env.DOTS_ENV_EXPORT | path join "base"))
$env.DOTS_ENV_CORE = ($env.DOTS_ENV_CORE? | default ($env.DOTS_ENV_EXPORT | path join "core"))
$env.DOTS_ENV_UTIL = ($env.DOTS_ENV_UTIL? | default ($env.DOTS_ENV_EXPORT | path join "utility"))
$env.DOTS_ENV_PKGS = ($env.DOTS_ENV_PKGS? | default ($env.DOTS_ENV_EXPORT | path join "package"))
$env.DOTS_ENV_PRJ = ($env.DOTS_ENV_PRJ? | default ($env.DOTS_ENV_EXPORT | path join "project"))

#{ Launch shell-specific configuration
let shell_name = "nushell"
let shell_rc = ($env.DOTS_CFG | path join "nushell" "config.nu")

#{ Load shell-specific configuration
if ($shell_rc | path exists) {
  # source $shell_rc
  print $"INFO >>= DOTS Shell =<< Initialized '($shell_name)' using '($shell_rc)'"
} else {
  print -e $"WARN >>= DOTS Shell =<< Missing configuration file for ($shell_name): '($shell_rc)'"
}
