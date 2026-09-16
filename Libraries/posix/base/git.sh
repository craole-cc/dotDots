#!/bin/sh

# ── Sync Module ───────────────────────────────────────────────────────────────

init_sync() {
  init_env || return 1

  shift # Consume '--sync' argument
  _msg="${*:-sync Victus}"

  readonly SUBMODULE_PATH="Configuration/hosts/Victus"
  readonly SUBMODULE_USER="Craole"
  readonly SUBMODULE_NAME="Victus"
  readonly PARENT_USER="craole-cc"
  readonly PARENT_NAME="dotDots"

  error_exit() {
    printf "❌ Error: %s\n" "$1" >&2
    if (return 0) 2> /dev/null; then return "${2:-1}"; else exit "${2:-1}"; fi
  }

  info() { printf "➡️  %s\n" "$1"; }
  success() { printf "✅ %s\n" "$1"; }
  skip() { printf "📌 %s\n" "$1"; }

  switch_gh_user() {
    if ! command -v gh > /dev/null 2>&1; then
      error_exit "GitHub CLI (gh) is not installed"
    fi
    info "Switching to GitHub user: $1..."
    gh auth switch --user "$1" > /dev/null 2>&1 \
      || error_exit "Failed to switch GitHub user to $1" 2
  }

  is_git_repo() { git rev-parse --git-dir > /dev/null 2>&1; }

  has_changes() {
    ! git diff-index --quiet HEAD -- 2> /dev/null && {
      _untracked="$(git ls-files --others --exclude-standard 2> /dev/null)"
      [ -z "${_untracked}" ]
    }
  }

  safe_cd() {
    [ ! -d "$1" ] && error_exit "Directory does not exist: $1"
    cd "$1" || error_exit "Cannot change to ${2:-directory}: $1"
  }

  git_exec() {
    _action="$1"
    shift
    git "$@" || error_exit "Git ${_action} failed" 3
  }

  info "Starting ${PARENT_NAME} sync: ${_msg}"

  # 1. Sync Submodule
  info "Processing ${SUBMODULE_NAME} submodule..."
  safe_cd "${DOTS:?}/${SUBMODULE_PATH}" "${SUBMODULE_NAME} submodule"
  is_git_repo || error_exit "${SUBMODULE_NAME} directory is not a git repository"
  switch_gh_user "${SUBMODULE_USER}"

  if has_changes; then
    info "Changes detected in ${SUBMODULE_NAME}"
    git_exec "add" add --all
    git_exec "commit" commit --message "${_msg}"
    git_exec "push" push
    success "${SUBMODULE_NAME} submodule synced"
  else
    skip "No changes in ${SUBMODULE_NAME} submodule"
  fi

  # 2. Sync Parent Repository
  info "Processing ${PARENT_NAME} parent repository..."
  safe_cd "${DOTS}" "${PARENT_NAME} root"
  is_git_repo || error_exit "${PARENT_NAME} directory is not a git repository"
  switch_gh_user "${PARENT_USER}"

  git_exec "add submodule" add "${SUBMODULE_PATH}"
  if git diff --cached --quiet -- "${SUBMODULE_PATH}" 2> /dev/null; then
    skip "No submodule pointer change in ${PARENT_NAME}"
  else
    git_exec "commit" commit --message "bump ${SUBMODULE_NAME} submodule: ${_msg}"
    git_exec "push" push
    success "${PARENT_NAME} parent repository updated"
  fi

  success "Complete: ${SUBMODULE_NAME} submodule + ${PARENT_NAME} sync finished"
}
