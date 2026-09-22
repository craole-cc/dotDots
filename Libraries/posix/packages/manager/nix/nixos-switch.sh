#!/bin/sh
set -eu

#~@ Main Orchestrator
main() {
  set_defaults
  ensure_dependencies
  parse_arguments "$@"
  commit_changes
  deploy_config
  switch_system
}

#~@ Defaults & Configuration
set_defaults() {
  host="${HOST:-$(hostname || printf "unknown")}"
  rev_core="${REV_CORE:-"https://releases.nixos.org/nixos/unstable/nixos-26.11pre1077143.44a91898084f/nixexprs.tar.zst"}"
  rev_home="${REV_HOME:-"https://github.com/nix-community/home-manager/archive/a3dfb887d40d134af29fa8e924ba85a3e3a99194.tar.gz"}"
  dots="${PRJ_DOTS:-${DOTS:-${HOME}/.dots}}"

  src="${dots}/API/nix/hosts/${host}"
  source="${SOURCE:-${src}}"
  target="${TARGET:-/etc/nixos}"
  mode="${MODE:-flake}"
  message=""
  dry_run="${DRY_RUN:-0}"
  verbosity="${VERBOSITY:-info}"
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

        level="${verbosity:-"INFO"}"
        msg=""
        extra_args=""

        while [ $# -gt 0 ]; do
          case "${1:-}" in
          --level)
            level="$(printf '%s' "${2:-}" | tr '[:lower:]' '[:upper:]')"
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

        printf "[%s] %s%s\n" "${level}" "${msg}" "${extra_args}" >&2
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
    --flake) mode="flake" ;;
    --legacy | --config) mode="config" ;;
    --message | --msg | -m)
      if [ -n "${2:-}" ]; then
        message="${2}"
        shift
      else
        gum log --level error "Argument requires a value" arg "${1:-}"
        exit 1
      fi
      ;;
    *)
      if [ -n "${message:-}" ]; then
        message="${message} ${1:-}"
      else
        message="${1:-}"
      fi
      ;;
    esac
    shift
  done

  if [ "${mode_dry_run:-0}" -eq 1 ]; then
    dry_run=1
  fi
}

#~@ Step 1: Commit Changes
commit_changes() {
  if command -v git >/dev/null 2>&1 &&
    git -C "${source}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [ -z "${message:-}" ]; then
      message="$(git -C "${source}" log -1 --pretty=%s 2>/dev/null || true)"
      [ -z "${message:-}" ] && message="update"
    fi

    if [ "${dry_run}" -eq 1 ]; then
      gum log \
        --level info \
        --structured "[DRY-RUN] Would commit changes" \
        source "${source}" \
        message "${message}"
      return 0
    fi

    git -C "${source}" add --all

    if ! git -C "${source}" diff --cached --quiet; then
      gum log \
        --level info \
        --structured "Committing changes" \
        source "${source}" \
        message "${message}"

      git -C "${source}" commit --message "${message}" --quiet
    fi
  fi
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
    sudo cp -a "${source}"/. "${target}/"
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
      --structured "[DRY-RUN] Would run nixos-rebuild switch" \
      host "${host}" \
      mode "${mode}" \
      source "${source}" \
      target "${target}" \
      dots "${dots}" \
      rev_core "${rev_core}" \
      rev_home "${rev_home}"
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
      -I "home-manager=${rev_home}"
    ;;
  *)
    gum log \
      --level error \
      --structured "Unknown mode" mode "${mode}"
    exit 1
    ;;
  esac
}

main "$@"
