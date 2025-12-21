#!/bin/sh
# Sync script for dotDots configuration repository
# Handles submodule updates with proper error checking and multi-user support
set -eu

#──────────────────────────────────────────────────────────────────────────────
# Configuration
#──────────────────────────────────────────────────────────────────────────────

SCRIPT_NAME="sync.dots"
readonly ROOT="${DOTS:-${HOME}/.dots}"

# Submodule configuration
readonly SUBMODULE_PATH="Configuration/hosts/Victus"
readonly SUBMODULE_USER="Craole"
readonly SUBMODULE_NAME="Victus"

# Parent repository configuration
readonly PARENT_USER="craole-cc"
readonly PARENT_NAME="dotDots"

# Separate declaration and assignment to avoid masking return values
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

# Get commit message from arguments or use default
readonly MSG="${*:-sync ${SUBMODULE_NAME}}"

#──────────────────────────────────────────────────────────────────────────────
# Helper Functions
#──────────────────────────────────────────────────────────────────────────────

# Print error message and exit
error_exit() {
	_err_msg="$1"
	_err_code="${2:-1}"
	printf "❌ Error: %s\n" "$_err_msg" >&2
	exit "$_err_code"
}

# Print info message
info() {
	printf "➡️  %s\n" "$1"
}

# Print success message
success() {
	printf "✅ %s\n" "$1"
}

# Print skip message
skip() {
	printf "📌 %s\n" "$1"
}

# Switch GitHub user safely
switch_gh_user() {
	_user="$1"

	if ! command -v gh >/dev/null 2>&1; then
		error_exit "GitHub CLI (gh) is not installed"
	fi

	info "Switching to GitHub user: ${_user}..."
	if ! gh auth switch --user "${_user}" >/dev/null 2>&1; then
		error_exit "Failed to switch GitHub user to ${_user}" 2
	fi
}

# Check if directory is a git repository
is_git_repo() {
	git rev-parse --git-dir >/dev/null 2>&1
}

# Check if there are uncommitted changes
has_changes() {
	! git diff-index --quiet HEAD -- 2>/dev/null ||
		[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]
}

# Safely change directory
safe_cd() {
	_target="$1"
	_description="${2:-directory}"

	if [ ! -d "${_target}" ]; then
		error_exit "Directory does not exist: ${_target}"
	fi

	if ! cd "${_target}"; then
		error_exit "Cannot change to ${_description}: ${_target}"
	fi
}

# Execute git command with error handling
git_exec() {
	_action="$1"
	shift

	if ! git "$@"; then
		error_exit "Git ${_action} failed" 3
	fi
}

#──────────────────────────────────────────────────────────────────────────────
# Main Functions
#──────────────────────────────────────────────────────────────────────────────

# Sync submodule repository
sync_submodule() {
	info "Processing ${SUBMODULE_NAME} submodule..."

	safe_cd "${ROOT}/${SUBMODULE_PATH}" "${SUBMODULE_NAME} submodule"

	if ! is_git_repo; then
		error_exit "${SUBMODULE_NAME} directory is not a git repository"
	fi

	switch_gh_user "${SUBMODULE_USER}"

	if has_changes; then
		info "Changes detected in ${SUBMODULE_NAME}"
		git_exec "add" add --all
		git_exec "commit" commit --message "${MSG}"
		git_exec "push" push
		success "${SUBMODULE_NAME} submodule synced"
	else
		skip "No changes in ${SUBMODULE_NAME} submodule"
	fi
}

# Update parent repository with submodule changes
sync_parent_repo() {
	info "Processing ${PARENT_NAME} parent repository..."

	safe_cd "${ROOT}" "${PARENT_NAME} root"

	if ! is_git_repo; then
		error_exit "${PARENT_NAME} directory is not a git repository"
	fi

	switch_gh_user "${PARENT_USER}"

	# Stage the submodule pointer change
	git_exec "add submodule" add "${SUBMODULE_PATH}"

	# Check if the submodule pointer actually changed
	if git diff --cached --quiet -- "${SUBMODULE_PATH}" 2>/dev/null; then
		skip "No submodule pointer change in ${PARENT_NAME}"
		return 0
	fi

	git_exec "commit" commit --message "bump ${SUBMODULE_NAME} submodule: ${MSG}"
	git_exec "push" push
	success "${PARENT_NAME} parent repository updated"
}

#──────────────────────────────────────────────────────────────────────────────
# Main Script
#──────────────────────────────────────────────────────────────────────────────

main() {
	info "Starting ${PARENT_NAME} sync: ${MSG}"

	# Verify root directory exists
	if [ ! -d "${ROOT}" ]; then
		error_exit "${PARENT_NAME} root directory not found: ${ROOT}"
	fi

	# Sync submodule and parent repository
	sync_submodule
	sync_parent_repo

	success "Complete: ${SUBMODULE_NAME} submodule + ${PARENT_NAME} sync finished"
}

# Execute main function
main
