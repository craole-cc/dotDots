#!/usr/bin/env bash
# shellcheck enable=all
#DOC SSH Git Setup Script
#DOC Automatically configure SSH for Git profiles based on dotfiles

set -e
set -o pipefail
shopt -s inherit_errexit #? Maintain set -e behavior in command substitutions

#@ Application info
APP_NAME="sshit"
APP_VERSION="1.2"

#@ Default paths
DOTS="${DOTS:-${HOME}/.dots}"
GIT_PROFILES_DIR="${DOTS}/Configuration/git/home"
SSH_DIR="${HOME}/.ssh"
SSH_CONFIG="${SSH_DIR}/config"

#@ Colors and formatting using tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

#@ Function to display help information
show_help() {
  cat <<EOF
${BOLD}${APP_NAME}${RESET} v${APP_VERSION}

Usage: ${APP_NAME} [OPTIONS]

Automatically configures SSH for Git based on your dotfiles.

Options:
  -h, --help      Show this help message and exit
  -v, --version   Show version information and exit
  -d, --dir DIR   Set custom dotfiles directory (default: ${DOTS})
  -f, --force     Force regeneration of existing keys
  -l, --list      List available profiles
  -y, --yes       Non-interactive mode (no prompts)

Examples:
  ${APP_NAME}
  ${APP_NAME} --dir ~/my-dotfiles
  ${APP_NAME} --force
  ${APP_NAME} --yes
EOF
}

#@ Function to display version information
show_version() {
  printf "%s v%s\n" "${APP_NAME}" "${APP_VERSION}"
}

#@ Function to display error messages
show_error() {
  printf "%s🚩 Error:%s %s\n" "${RED}" "${RESET}" "$1" >&2
}

#@ Function to display success messages
show_success() {
  printf "%s✓ Success:%s %s\n" "${GREEN}" "${RESET}" "$1"
}

#@ Function to display information messages
show_info() {
  printf "%sℹ Info:%s %s\n" "${BLUE}" "${RESET}" "$1"
}

#@ Function to display warning messages
show_warning() {
  printf "%s⚠ Warning:%s %s\n" "${YELLOW}" "${RESET}" "$1"
}

#@ Function to display a prompt message
show_prompt() {
  printf "%s> Prompt:%s %s\n" "${MAGENTA}" "${RESET}" "$1"
}

#@ Function to display instructions
show_instruction() {
  printf "%s📝 Instruction:%s %s\n" "${CYAN}" "${RESET}" "$1"
}

#@ Function to get system information for SSH key comment
get_system_info() {
  local hostname email
  hostname=$(hostname)
  email="$1"

  local os_info
  if [[ -f /etc/os-release ]]; then
    #| Linux
    os_info=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  elif command -v uname &>/dev/null; then
    #| macOS or other Unix
    os_info=$(uname -s)
  else
    #| Fallback
    os_info="Unknown"
  fi

  #@ Combine hostname, OS, and email
  printf "%s-%s-%s" "${hostname}" "${os_info}" "${email}"
}

#@ Function to copy text to clipboard
copy_to_clipboard() {
  local text="$1"
  local success=false

  #@ Try different clipboard commands based on available tools
  if command -v xclip &>/dev/null; then
    echo -n "${text}" | xclip -selection clipboard && success=true
  elif command -v xsel &>/dev/null; then
    echo -n "${text}" | xsel --clipboard --input && success=true
  elif command -v pbcopy &>/dev/null; then
    echo -n "${text}" | pbcopy && success=true
  elif command -v clip.exe &>/dev/null; then
    #@ For Windows/WSL
    echo -n "${text}" | clip.exe && success=true
  elif [[ -n ${WAYLAND_DISPLAY} ]] && command -v wl-copy &>/dev/null; then
    echo -n "${text}" | wl-copy && success=true
  fi

  if ${success}; then
    show_success "Copied to clipboard"
    return 0
  else
    show_warning "Could not copy to clipboard - no supported clipboard utility found"
    return 1
  fi
}

#@ Function to parse Git config file and extract SSH information
parse_git_config() {
  local config_file="$1"
  local filename
  filename="$(basename "${config_file}")"

  #@ Extract host and username from filename (format: host_username.gitconfig)
  local host username
  IFS='_' read -r host username <<<"$(basename "${filename}" .gitconfig)"

  #@ Read git user information from config - avoid command substitution masking
  local git_name git_email ssh_path

  #@ Handle each command separately to avoid masking return values
  local name_line email_line ssh_line
  name_line=$(grep -A 1 "\[user\]" "${config_file}" | grep "name" || true)
  if [[ -n "${name_line}" ]]; then
    git_name=$(printf "%s" "${name_line}" | cut -d= -f2 | tr -d ' "' || true)
  else
    git_name=""
  fi

  email_line=$(grep -A 2 "\[user\]" "${config_file}" | grep "email" || true)
  if [[ -n "${email_line}" ]]; then
    git_email=$(printf "%s" "${email_line}" | cut -d= -f2 | tr -d ' "' || true)
  else
    git_email=""
  fi

  ssh_line=$(grep "sshCommand" "${config_file}" || true)
  if [[ -n "${ssh_line}" ]]; then
    ssh_cmd=$(printf "%s" "${ssh_line}" | grep -o '"ssh -i [^"]*"' || true)
    if [[ -n "${ssh_cmd}" ]]; then
      ssh_path=$(printf "%s" "${ssh_cmd}" | cut -d' ' -f3 | tr -d '"' || true)
    else
      ssh_path=""
    fi
  else
    ssh_path=""
  fi

  #@ Normalize host (add .com if missing)
  if ! printf "%s" "${host}" | grep -q '\.'; then
    host="${host}.com"
  fi

  #@ Only output the variable assignments - no debug info
  printf "host=%q\n" "${host}"
  printf "username=%q\n" "${username}"
  printf "git_name=%q\n" "${git_name}"
  printf "git_email=%q\n" "${git_email}"
  printf "ssh_path=%q\n" "${ssh_path}"
}

#@ Function to generate SSH key
generate_ssh_key() {
  local host="$1"
  local username="$2"
  local email="$3"
  local key_path="$4"
  local force="$5"
  local non_interactive="$6"

  #@ Ensure any tildes in the path are expanded
  if [[ "${key_path}" == *"~"* ]]; then
    key_path="${key_path/#\~/${HOME}}"
    key_path="${key_path//\~/${HOME}}"
    show_info "Expanded tilde in key path: ${key_path}"
  fi

  #@ Create directory for key if it doesn't exist
  local key_dir
  key_dir="$(dirname "${key_path}")"
  mkdir -p "${key_dir}"
  show_info "Created directory: ${key_dir}"

  #@ Check if key already exists
  if [[ -f "${key_path}" && "${force}" != "true" ]]; then
    show_warning "SSH key already exists at ${key_path}. Use --force to regenerate."
    return 0
  elif [[ -f "${key_path}" && "${force}" == "true" ]]; then
    #@ Archive existing key
    local archive_dir="${key_dir}/archive"
    mkdir -p "${archive_dir}"
    show_info "Created archive directory: ${archive_dir}"

    local timestamp
    timestamp="$(date +"%Y%m%d%H%M%S")"
    mv "${key_path}" "${archive_dir}/$(basename "${key_path}").${timestamp}"
    show_info "Archived key: ${archive_dir}/$(basename "${key_path}").${timestamp}"

    if [[ -f "${key_path}.pub" ]]; then
      mv "${key_path}.pub" "${archive_dir}/$(basename "${key_path}").pub.${timestamp}"
      show_info "Archived public key: ${archive_dir}/$(basename "${key_path}").pub.${timestamp}"
    fi
    show_info "Archived existing key to ${archive_dir}"
  fi

  #@ Generate key comment with system information
  local key_comment
  key_comment=$(get_system_info "${email}")
  show_info "Using SSH key comment: ${key_comment}"

  #@ Generate SSH key
  show_info "Generating SSH key for ${username}@${host}"
  ssh-keygen -t ed25519 -a 100 -f "${key_path}" -C "${key_comment}" -N ""
  show_info "Created key files: ${key_path} and ${key_path}.pub"

  #@ Add to SSH config
  printf "\nHost %s\n  User %s\n  HostName %s\n  IdentityFile %s\n" \
    "${host}" "${username}" "${host}" "${key_path}" >>"${SSH_CONFIG}"
  show_info "Updated SSH config: ${SSH_CONFIG}"

  #@ Add key to SSH agent - handle commands separately
  #@ Start ssh-agent
  local agent_output
  agent_output=$(ssh-agent -s)
  eval "${agent_output}" >/dev/null
  show_info "Started SSH agent"

  #@ Add key to agent
  ssh-add "${key_path}" >/dev/null || true
  show_info "Added key to SSH agent"

  show_success "SSH key generated for ${username}@${host}"

  #@ Explicitly copy public key to clipboard
  local pub_key
  pub_key=$(cat "${key_path}.pub")
  copy_to_clipboard "${pub_key}"

  #@ Display the public key
  printf "\n%sPublic Key:%s\n" "${YELLOW}" "${RESET}"
  cat "${key_path}.pub"
  printf "\n"

  #@ Prompt user to add key to Git host if in interactive mode
  if [[ "${non_interactive}" != "true" ]]; then
    show_instruction "Please add this SSH key to your ${host} account:"
    show_instruction "1. Login to ${host}"
    show_instruction "2. Navigate to SSH keys settings"
    show_instruction "3. Add a new SSH key"
    show_instruction "4. Paste the key (should be in your clipboard)"
    show_instruction "5. Save the key"

    show_prompt "Press Enter when you've added the key to your ${host} account, or Ctrl+C to exit"
    read -r

    #@ Validate the key by testing connection
    validate_ssh_connection "${host}" "${username}" "${key_path}"
  fi
}

#@ Function to validate SSH connection
validate_ssh_connection() {
  local host="$1"
  local username="$2"
  local key_path="$3"
  local ssh_check_cmd="ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=accept-new -T -i \"${key_path}\" git@\"${host}\""

  show_info "Validating SSH connection to ${host}..."
  show_info "> ${ssh_check_cmd}"

  #@ Try the connection with auto-accepting host keys
  #TODO test if this still works with the eval
  # if ssh -o StrictHostKeyChecking=accept-new -T -i "${key_path}" git@"${host}" 2>&1 |
  #   grep -i -q "success\|welcome\|authenticated"; then
  if eval "${ssh_check_cmd}" 2>&1 | grep -i -q "success\|welcome\|authenticated"; then
    show_success "Successfully authenticated with ${host}!"
    return 0
  else
    show_warning "Could not authenticate with ${host}. The key may not be properly added yet."
    return 1
  fi
}

#@ Function to list available profiles
list_profiles() {
  if [[ ! -d "${GIT_PROFILES_DIR}" ]]; then
    show_error "Git profiles directory not found: ${GIT_PROFILES_DIR}"
    exit 1
  fi

  printf "%s\n" "${BOLD}Available Git Profiles:${RESET}"

  #@ Find gitconfig files
  local configs=()

  #@ Handle find separately to avoid masking return values
  local find_output
  find_output=$(find "${GIT_PROFILES_DIR}" -name "*.gitconfig" -type f || true)

  if [[ -z "${find_output}" ]]; then
    printf "  No profiles found\n"
    return
  fi

  #@ Read find output into array
  mapfile -t configs <<<"${find_output}"

  for config_file in "${configs[@]}"; do
    local filename
    filename="$(basename "${config_file}")"
    printf "  - %s\n" "${filename}"
  done
}

#@ Function to setup SSH for all profiles
setup_ssh_for_profiles() {
  local force="$1"
  local non_interactive="$2"

  #@ Ensure SSH directory exists
  mkdir -p "${SSH_DIR}"
  show_info "Created SSH directory: ${SSH_DIR}"

  show_info "Using SSH directory: ${SSH_DIR}"
  if [[ -d "${SSH_DIR}/~" ]]; then
    show_warning "Found unusual '~' folder in SSH_DIR, this may indicate a path issue"
  fi

  touch "${SSH_CONFIG}"
  show_info "Ensured SSH config exists: ${SSH_CONFIG}"

  #@ Check if git profiles directory exists
  if [[ ! -d "${GIT_PROFILES_DIR}" ]]; then
    show_error "Git profiles directory not found: ${GIT_PROFILES_DIR}"
    exit 1
  fi

  #@ Find all gitconfig files - handle separately to avoid masking
  local find_output
  find_output=$(find "${GIT_PROFILES_DIR}" -name "*.gitconfig" -type f || true)

  if [[ -z "${find_output}" ]]; then
    show_error "No Git configurations found in ${GIT_PROFILES_DIR}"
    exit 1
  fi

  #@ Read find output into array
  local configs=()
  mapfile -t configs <<<"${find_output}"

  #@ Process each gitconfig file
  for config_file in "${configs[@]}"; do
    printf "\n%sProcessing:%s %s\n" "${BOLD}" "${RESET}" "$(basename "${config_file}")"

    #@ Extract filename info for logging, separate from the parsing function
    local filename host username
    filename="$(basename "${config_file}")"
    IFS='_' read -r host username <<<"$(basename "${filename}" .gitconfig)"
    show_info "Extracted from filename: host='${host}', username='${username}'"

    #@ Normalize host for logging
    if ! printf "%s" "${host}" | grep -q '\.'; then
      host="${host}.com"
      show_info "Normalized host to: ${host}"
    fi

    #@ Parse git config to get ssh information - handle separately
    local profile_info
    profile_info=$(parse_git_config "${config_file}")

    #@ Show debug info - AFTER capturing the output, not mixed with it
    show_info "Debug - profile_info contains: ${profile_info}"

    #@ Source the profile info to create variables
    eval "${profile_info}" || {
      show_error "Failed to evaluate profile info: ${profile_info}"
      continue #? Skip this profile if it fails
    }
    show_info "Evaluated variables: host='${host}', username='${username}', git_email='${git_email}'"

    #@ Use parsed SSH_PATH or generate one based on host and username
    if [[ -n "${ssh_path}" && "${ssh_path}" == *"~"* ]]; then

      #@ Replace ~ with $HOME
      ssh_path="${ssh_path/#\~/${HOME}}"

      #@ Also handle cases where ~ might be elsewhere in the path
      ssh_path="${ssh_path//\~/${HOME}}"

      show_info "Expanded tilde in SSH path: ${ssh_path}"
    fi
    if [[ -z "${ssh_path}" ]]; then
      ssh_path="${SSH_DIR}/${host}/${username}"
      ssh_path="${ssh_path//\/\//\/}"
      show_info "Set ssh_path to: ${ssh_path}"
    fi

    #@ Generate SSH key and handle interactive setup
    generate_ssh_key "${host}" "${username}" "${git_email}" "${ssh_path}" "${force}" "${non_interactive}"
  done

  show_success "SSH configuration complete."

  #@ Final instructions
  if [[ "${non_interactive}" != "true" ]]; then
    printf "\n%sFinal Steps:%s\n" "${BOLD}" "${RESET}"
    show_instruction "Your SSH keys have been set up and tested."
    show_instruction "You can now use Git with SSH for these profiles."
    show_instruction "To test a connection manually, try: ssh -T git@github.com"
  fi
}

#@ Main function
main() {
  local force="false"
  local non_interactive="false"

  #@ Parse command line arguments
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -v | --version)
      show_version
      exit 0
      ;;
    -d | --dir)
      DOTS="$2"
      GIT_PROFILES_DIR="${DOTS}/Configuration/git/home"
      shift 2
      ;;
    -f | --force)
      force="true"
      shift
      ;;
    -l | --list)
      list_profiles
      exit 0
      ;;
    -y | --yes)
      non_interactive="true"
      shift
      ;;
    *)
      show_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
  done

  #@ Display header
  printf "%s\n\n" "${BOLD}${APP_NAME}${RESET} v${APP_VERSION}"

  #@ Setup SSH for profiles
  setup_ssh_for_profiles "${force}" "${non_interactive}"
}

#@ Run the script
main "$@"
