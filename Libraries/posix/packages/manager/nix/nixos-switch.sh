#!/bin/sh
set -eu

#~@ Main Orchestrator
main() {
  set_defaults
  parse_arguments "$@"
  verbosity normalize
  ensure_dependencies
  check_flake_staleness
  deploy_config
  switch_system
}

#~@ Defaults & Configuration
set_defaults() {
  verbosity="${VERBOSITY:-${LOG_LEVEL:-$(verbosity level)}}"

  rev_core="${REV_URL_CORE:-"https://releases.nixos.org/nixos/unstable/nixos-26.11pre1077143.44a91898084f/nixexprs.tar.zst"}"
  rev_home="${REV_URL_HOME:-"https://github.com/nix-community/home-manager/archive/a3dfb887d40d134af29fa8e924ba85a3e3a99194.tar.gz"}"
  rev_apps="${REV_URL_INDEX:-"https://github.com/nix-community/nix-index-database/archive/9ad722673ab3b3f91f02135e53775825b240b869.tar.gz"}"

  dots="${DOTS:?}"
  host="${HOST:-$(hostname || printf "unknown")}"
  source="${SOURCE:-${DOTS_HOSTS:-${dots:?}/API/nix/hosts}/${host}}"
  target="${TARGET:-${DOTS_BUILD:-/etc/nixos}}"
  mode="${MODE:-flake}"
  dry_run="${DRY_RUN:-0}"
  dry_action="${DRY_ACTION:-dry-build}"
  max_age_days="${FLAKE_MAX_AGE_DAYS:-7}"
  skip_stale_check="${SKIP_FLAKE_CHECK:-0}"
}

#~@ Unified Verbosity Handler
verbosity() {
  def_lvl=2

  case "${1:-normalize}" in
  priority)
    case "$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]')" in
    debug | trace | v | verbose | 3) printf '1' ;;
    info | notice | i | 2) printf '2' ;;
    warn | warning | w | 1) printf '3' ;;
    error | err | e | 0 | fatal) printf '4' ;;
    quiet | silent | q | none | off) printf '5' ;;
    *) verbosity priority "${def_lvl}" ;;
    esac
    ;;
  level)
    case "${2:-${def_lvl}}" in
    1) printf 'debug' ;;
    2) printf 'info' ;;
    3) printf 'warn' ;;
    4) printf 'error' ;;
    5) printf 'none' ;;
    *) verbosity level "${def_lvl}" ;;
    esac
    ;;
  normalize)
    verbosity_priority="$(verbosity priority "${verbosity}")"
    verbosity="$(verbosity level "${verbosity_priority}")"
    export GUM_LOG_LEVEL="${verbosity}"
    ;;
  *) ;;
  esac
}

#~@ Dependency Provisioning & Validation
ensure_dependencies() {
  # 1. Provision gum (binary in PATH, nix-shell resolution, or printf wrapper fallback)
  if ! command -v gum >/dev/null 2>&1; then
    if command -v nix-shell >/dev/null 2>&1; then
      gum_bin="$(nix-shell -p gum -I "nixpkgs=${rev_core}" --run "command -v gum" 2>/dev/null || true)"
      if [ -n "${gum_bin:-}" ] && [ -x "${gum_bin}" ]; then
        PATH="$(dirname "${gum_bin}"):${PATH}"
        export PATH
      fi
    fi

    if ! command -v gum >/dev/null 2>&1; then
      gum() {
        [ "${1:-}" = "log" ] || return 0
        shift

        level=""
        msg=""
        extra_args=""

        while [ $# -gt 0 ]; do
          case "${1:-}" in
          --level)
            level="${2:-}"
            shift
            ;;
          --structured)
            msg="${2:-}"
            shift
            ;;
          *) extra_args="${extra_args} ${1:-}" ;;
          esac
          shift
        done

        msg_prio="$(verbosity priority "${level}")"

        if [ "${msg_prio}" -ge "${verbosity_priority}" ]; then
          display_level="$(verbosity level "${msg_prio}" | tr '[:lower:]' '[:upper:]')"
          printf "[%s] %s%s\n" "${display_level}" "${msg}" "${extra_args}" >&2
        fi
      }
    fi
  fi

  # 2. Check essential system dependencies
  for cmd in sudo nixos-rebuild; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      gum log \
        --level error \
        --structured "Required command not found" command "${cmd}"
      exit 1
    fi
  done
}

#~@ Argument Parsing
parse_arguments() {
  while [ $# -gt 0 ]; do
    case "${1:-}" in
    --dry-run | -n) mode_dry_run=1 ;;
    --dry-activate) dry_action="dry-activate" ;;
    --no-flake-check) skip_stale_check=1 ;;
    --max-age)
      if [ -n "${2:-}" ]; then
        max_age_days="${2}"
        shift
      else
        gum log --level error "Argument requires a value" arg "${1:-}"
        exit 1
      fi
      ;;
    --flake) mode="flake" ;;
    --legacy | --config) mode="config" ;;
    -v | --verbose) verbosity="debug" ;;
    -q | --quiet) verbosity="none" ;;
    -h | --help)
      show_help
      exit 0
      ;;
    --verbosity | --level | --log-level)
      if [ -n "${2:-}" ]; then
        verbosity="${2}"
        shift
      else
        gum log --level error "Argument requires a value" arg "${1:-}"
        exit 1
      fi
      ;;
    *)
      gum log --level error "Unknown argument" arg "${1:-}"
      exit 1
      ;;
    esac
    shift
  done

  if [ "${mode_dry_run:-0}" -eq 1 ]; then
    dry_run=1
  fi
}

#~@ Step 1: Check Flake Staleness & Update if Needed
check_flake_staleness() {
  [ "${skip_stale_check:-0}" -eq 1 ] && return 0
  command -v nix >/dev/null 2>&1 || {
    gum log --level warn --structured "nix not found - skipping flake staleness check"
    return 0
  }

  lock="${dots}/flake.lock"
  [ -f "${lock}" ] || {
    gum log --level warn --structured "flake.lock not found" path "${lock}"
    return 0
  }

  # Prefer git history for the lock's true last-change time; `mtime` lies
  # after a fresh clone/download. Fall back to file `mtime` if not a repo.
  if command -v git >/dev/null 2>&1 &&
    git -C "${dots}" rev-parse \
      --is-inside-work-tree >/dev/null 2>&1; then
    last_change="$(
      git -C "${dots}" log -1 \
        --format=%ct \
        -- flake.lock 2>/dev/null || true
    )"
  fi
  [ -n "${last_change:-}" ] ||
    last_change="$(
      stat -c %Y "${lock}" 2>/dev/null ||
        stat -f %m "${lock}" 2>/dev/null ||
        printf 0
    )"

  now="$(date +%s)"
  age_days="$(((now - last_change) / 86400))"

  if [ "${age_days}" -lt "${max_age_days}" ]; then
    gum log \
      --level debug \
      --structured "Flake lock is fresh" age_days "${age_days}" max_age_days "${max_age_days}"
    return 0
  fi

  gum log \
    --level warn \
    --structured "Flake lock is stale" age_days "${age_days}" max_age_days "${max_age_days}"

  if [ "${dry_run}" -eq 1 ]; then
    gum log \
      --level info \
      --structured "[DRY-RUN] Would update flake inputs" flake "${dots}"
    return 0
  fi

  gum log \
    --level info \
    --structured "Updating flake inputs" flake "${dots}"

  nix flake update --flake "${dots}"
}

#~@ Step 2: Deploy to Target
deploy_config() {
  if [ -d "${source}" ]; then
    if [ "${dry_run}" -eq 1 ]; then
      gum log \
        --level info \
        --structured "[DRY-RUN] Would sync config" \
        source "${source}" \
        target "${target}"
      return 0
    fi

    gum log \
      --level info \
      --structured "Syncing config" \
      source "${source}" \
      target "${target}"

    sudo mkdir -p "${target}"

    rsync_flags="-a --no-owner --no-group --delete --exclude=.git"
    #? `verbosity_priority`: 1=debug 2=info 3=warn 4=error 5=none(quiet)
    if [ "${verbosity_priority}" -lt 5 ]; then
      rsync_flags="${rsync_flags} -v"
    fi

    # shellcheck disable=SC2086
    sudo rsync ${rsync_flags} "${source}/" "${target}/"
  else
    gum log \
      --level warn \
      --structured "Source not found - building with existing target" \
      source "${source}" \
      target "${target}"
  fi
}

#~@ Step 3: Switch NixOS System
switch_system() {
  if [ "${dry_run}" -eq 1 ]; then
    gum log \
      --level info \
      --structured "Running ${dry_action} against source (no sync, no switch)" \
      host "${host}" \
      action "${dry_action}" \
      source "${source}"

    # dry-build only evaluates+builds: no root needed, and running it as
    # root would fail against a repo root doesn't own (git safe.directory).
    # dry-activate needs root to inspect the live system for the diff.
    case "${dry_action}" in
    dry-build) rebuild_cmd="nixos-rebuild" ;;
    *) rebuild_cmd="sudo nixos-rebuild" ;;
    esac

    case "${mode:-}" in
    flake)
      ${rebuild_cmd} "${dry_action}" \
        --flake "${source}#${host}"
      ;;
    config)
      ${rebuild_cmd} "${dry_action}" \
        --no-flake \
        -I "nixos-config=${source}/configuration.nix" \
        -I "nixpkgs=${rev_core}" \
        -I "home-manager=${rev_home}" \
        -I "nix-index-database=${rev_apps}"
      ;;
    *)
      gum log \
        --level error \
        --structured "Unknown mode" mode "${mode}"
      exit 1
      ;;
    esac
    return 0
  fi

  gum log \
    --level info \
    --structured "Starting nixos-rebuild" mode "${mode}" host "${host}"

  case "${mode:-}" in
  flake)
    sudo nixos-rebuild switch \
      --flake "${target}#${host}"
    ;;
  config)
    sudo nixos-rebuild switch \
      --no-flake \
      -I "nixos-config=${target}/configuration.nix" \
      -I "nixpkgs=${rev_core}" \
      -I "home-manager=${rev_home}" \
      -I "nix-index-database=${rev_apps}"
    ;;
  *)
    gum log \
      --level error \
      --structured "Unknown mode" mode "${mode}"
    exit 1
    ;;
  esac
}

#~@ Help / Usage
show_help() {
  here="$(basename "$0")"
  cat <<EOF
Usage: ${here} [OPTIONS]

Commits dots changes, syncs the host config to /etc/nixos, and runs
nixos-rebuild switch. Optionally checks flake.lock staleness first.

OPTIONS
  -n, --dry-run              Run nixos-rebuild's \${dry_action} against
                              SOURCE instead of switching (no commit sync,
                              no /etc/nixos sync, no switch)
                              (default: ${dry_run})
  --dry-activate              Under --dry-run, use 'nixos-rebuild dry-activate'
                              instead of 'dry-build' (shows activation diff,
                              needs root)
                              (default action: ${dry_action})

  --flake                    Build via 'nixos-rebuild switch --flake'
                              (default mode)
  --legacy, --config         Build via legacy -I channel args instead
                              (current mode: ${mode})

  --no-flake-check           Skip the flake.lock staleness check entirely
                              (default: ${skip_stale_check})
  --max-age <days>           Age in days before flake.lock is considered
                              stale and gets updated
                              (default: ${max_age_days})

  -v, --verbose               Set verbosity to debug
  -q, --quiet                 Set verbosity to none
  --verbosity, --level,
  --log-level <level>         debug|info|warn|error|none
                              (default: ${verbosity})

  -h, --help                  Show this help and exit

ENVIRONMENT (override any default above without flags)
  HOST                    Target host
  (current: ${host})

  DOTS                    Path to dots repo
  (current: ${dots})

  SOURCE                  Host config source dir
  (current: ${source})

  TARGET                  Deploy target dir
  (current: ${target})

  MODE                    flake|legacy
  (current: ${mode})

  DRY_RUN                 1|0
  (current: ${dry_run})

  DRY_ACTION              dry-build|dry-activate (dry-run action)
  (current: ${dry_action})

  SKIP_FLAKE_CHECK        1|0
  (current: ${skip_stale_check})

  FLAKE_MAX_AGE_DAYS      Days before lock is stale
  (current: ${max_age_days})

  VERBOSITY|LOG_LEVEL     debug|info|warn|error|none
  (current: ${verbosity})

  REV_URL_CORE            Legacy-mode nixpkgs channel URL
  (current: ${rev_core})

  REV_URL_HOME            Legacy-mode home-manager channel URL
  (current: ${rev_home})

  REV_URL_INDEX           Legacy-mode nix-index channel URL
  (current: ${rev_apps})


EXAMPLES
  # Dry-build against source for host Preci, no changes made
  DRY_RUN=1 HOST=Preci ${here}

  # Dry-activate (show activation diff) instead of dry-build
  HOST=Preci ${here} --dry-run --dry-activate

  # Force a flake update regardless of lock age, then switch
  FLAKE_MAX_AGE_DAYS=0 HOST=Preci ${here}

  # Skip the staleness check for a fast local iteration loop
  ${here} --no-flake-check -m "quick fix"
EOF
}

main "$@"
