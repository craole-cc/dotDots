#!/usr/bin/env bash
# shellcheck enable=all
#DOC SSH Git Setup Script
#DOC Automatically configure SSH for Git profiles based on dotfiles

main() {
  set_defaults
  parse_arguments "$@"
  execute_process

  #{ Skip if name and email are missing
  IFS="${old_ifs}"
}

set_defaults() {
  #| Operation modes
  set -e
  set -o pipefail
  shopt -s inherit_errexit #? Maintain set -e behavior in command substitutions

  #| Application info
  APP_NAME="sshit"
  APP_VERSION="1.2"

  #| Default paths
  DOTS="${DOTS:-${HOME}/.dots}"
  GIT_PROFILES_DIR="${DOTS}/Configuration/git/home"
  GIT_PROFILES=""
  SSH_DIR="${HOME}/.ssh"
  SSH_CONFIG="${SSH_DIR}/config"

  #| Colors and formatting using tput
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  MAGENTA=$(tput setaf 5)
  CYAN=$(tput setaf 6)
  BOLD=$(tput bold)
  RESET=$(tput sgr0)

  #| Default variables
  DELIMITER="${DELIMITER:-"$(printf "\037")"}"
  old_ifs="${IFS}"
  IFS="${DELIMITER}"
  host=""
  user_name=""
  user_email=""
  ssh_path=""
  ssh_cmd=""
  git_profiles=""

  #| Default flags
  verbosity="trace"
  # force="true"
  unattended="false"
}

parse_arguments() {
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
    -d | --dots)
      DOTS="$2"
      shift
      ;;
    -p | --profiles)
      GIT_PROFILES_DIR="$2"
      shift
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
      pout --error "Unknown option:" "$1"
      pout --help
      exit 1
      ;;
    esac
    shift
  done

  pout --debug-or error "GIT_PROFILES_DIR" "${GIT_PROFILES_DIR}"
  pout --debug-or error "SSH_DIR" "${SSH_DIR}"
  pout --debug-or error "SSH_CONFIG" "${SSH_CONFIG}"
  pout --debug-or error "force" "${force}"
  pout --debug-or error "non_interactive" "${non_interactive}"

  if
    false ||
      [[ -n "${GIT_PROFILES_DIR}" ]] ||
      [[ -n "${SSH_DIR}" ]] ||
      [[ -n "${SSH_CONFIG}" ]]
  then :; else
    pout --error "GIT_PROFILES_DIR, SSH_DIR, and SSH_CONFIG must be set"
    exit 1
  fi

  if [[ -d "${GIT_PROFILES_DIR}" ]]; then :; else
    pout --error "DOTS and GIT_PROFILES_DIR must be valid directories"
    exit 1
  fi
}

#{ Function to setup SSH for all profiles
execute_process() {
  get_or_create_ssh_config
  process_git_profiles

  # #{ Process each gitconfig file
  # for config_file in ${git_profiles}; do
  #   pout --trace "${BOLD}Processing: ${RESET}" \
  #     "$(basename "${config_file}" | sed "s|.gitconfig||g")"

  #   #{ Parse gitconfig file
  #   parse_gitconfig "${config_file}"

  #   #{ Generate SSH key and handle interactive setup
  #   generate_ssh_key \
  #     --host "${host}" \
  #     --name "${username}" \
  #     --email "${git_email}" \
  #     --path "${ssh_path}" \
  #     --cmd "${ssh_cmd}"

  # pout --info "SSH configuration complete."

  # #{ Final instructions
  # case "${unattended}" in
  # "" | false | off)
  #   printf "\n%sFinal Steps:%s\n" "${BOLD}" "${RESET}"
  #   pout --info "Your SSH keys have been set up and tested."
  #   pout --info "You can now use Git with SSH for these profiles."
  #   pout --info "To test a connection manually, try: ssh -T git@github.com"
  #   ;;
  # *) ;;
  # esac

  # done
}

fetch_info() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --os)
      nixos-version="$(nixos-version 2>/dev/null | awk '{print $1}' || true)"
      nixos-wsl-version="$(nixos-wsl-version 2>/dev/null || true)"

      if command -v nix >/dev/null 2>&1; then
        printf "NixOS"
      else
        case "$(uname | tr '[:upper:]' '[:lower:]')" in
        *linux*) printf "Linux" ;;
        *msys* | *ming* | *cygwin*) printf "Windows" ;;
        *darwin*) printf "MacOS" ;;
        *) printf "unknown" ;;
        esac
      fi
      ;;
    --user)
      printf "%s" "${USER:-"${USERNAME:-""}"}"
      ;;
    *) ;;
    esac
    shift
  done
}

get_system_info() {
  #{ Check if nix is installed
  if command -v nix >/dev/null 2>&1; then
    pout --trace "Nix is installed"
  else
    pout --error "Nix is not installed"
    exit 1
  fi
}

get_or_create_ssh_config() {
  #{ Ensure SSH directory exists
  mkdir -p "${SSH_DIR}"
  pout --trace "Ensured SSH directory: ${SSH_DIR}"
  pout --info "Using SSH directory: ${SSH_DIR}"

  #{ Check if SSH directory has '~', this is a common issue
  if [[ ! -d "${SSH_DIR}/~" ]]; then :; else
    pout --warning "Found unusual '~' folder in SSH_DIR, this may indicate a path issue"
  fi

  #{ Ensure SSH config exists
  touch "${SSH_CONFIG}"
  pout --trace "Ensured SSH config exists: ${SSH_CONFIG}"
}

get_git_profiles() {
  #{ Check if git profiles directory exists
  if [[ -d "${GIT_PROFILES_DIR}" ]]; then
    pout --trace "Found git profiles directory: ${GIT_PROFILES_DIR}"
  else
    pout --error "Git profiles directory not found: ${GIT_PROFILES_DIR}"
    exit 1
  fi

  #{ Find all gitconfig files - handle separately to avoid masking
  GIT_PROFILES="$(
    find "${GIT_PROFILES_DIR}" -type f -name "*.gitconfig" |
      tr '\n' "${DELIMITER}" || true
  )"
  GIT_PROFILES="${GIT_PROFILES%"${DELIMITER}"}" #? Remove the trailing delimiter

  if [[ -n "${GIT_PROFILES}" ]]; then
    local _configs _sep
    _sep=", "
    _configs="$(
      printf "%s" "${GIT_PROFILES}" |
        sed "s|.gitconfig||g" |
        sed "s|${GIT_PROFILES_DIR}/|${_sep}|g"
    )"
    _configs="${_configs#"${_sep}"}" #? Remove the leading delimiter
    pout --trace "Found possible git profiles: " "${_configs}"
  else
    pout --error "No Git configurations found in ${GIT_PROFILES_DIR}"
    exit 1
  fi
}

process_git_profiles() {
  get_git_profiles

  ifs="${IFS}"
  IFS="${DELIMITER}"
  for _path in ${GIT_PROFILES}; do
    #{ Set variables
    _name="${_path##*/}"            #? Remove the path, retaining the filename
    _name="${_name%.gitconfig}"     #? Remove the file extension
    _env="${_path%/*}/${_name}.env" #? Add the .env extension

    #{ Check for user group
    if grep -q '^\[user\]' "${_path}"; then
      pout --trace "Proceeding with git user profile: ${_name}"
    else
      pout --trace "Skipping profile due to missing user group: ${_name}"
      return
    fi

    #@Attempt to parse the host from the filename
    case "$(printf "%s" "${_path}" | tr '[:upper:]' '[:lower:]')" in
    *github*) host="github.com" ;;
    *gitlab*) host="gitlab.com" ;;
    *) host="" ;;
    esac
    pout --debug-or warn "Host" "${host}" "Parsed host from filename: ${host}"

    #{ Generate .env file, if necessary
    if [[ ! -f "${_env}" ]]; then
      pout --trace "Generating .env file for ${_name}"
      generate_ssh_env
      parse_ssh_info_from_file "${_path}" >"${_env}"
    else
      case "${force:-}" in
      1 | true | on)
        pout --warn "Overriding existing .env file for ${_name}"
        generate_ssh_env
        ;;
      *)
        pout --trace "Proceeding with existing .env file for ${_name}"
        ;;
      esac
    fi

    #{ Parse variables from .env file
    if [[ -s "${_env}" ]]; then
      #{ Read uncommented lines as key-value pairs and assign to shell variables
      _tmp="${_env}.tmp.$$"
      grep -v '^[[:space:]]*#' "${_env}" >"${_tmp}"
      while IFS='=' read -r key value; do
        case "${key}" in
        name) user_name="${value}" ;;
        email) user_email="${value}" ;;
        ssh_cmd) ssh_cmd="${value}" ;;
        ssh_path) ssh_path="${value}" ;;
        host) host="${value}" ;;
        *) ;;
        esac
      done <"${_tmp}"
      rm -f "${_tmp}"

      #{ Check for required variables
      pout --debug-or warn "Host" "${host}" "Profile skipped due to missing host: ${_name}"
      pout --debug-or warn "Email" "${user_email}" "Profile skipped due to missing email: ${_name}"
      pout --debug-or warn "Name" "${user_name}" "Profile skipped due to missing name: ${_name}"

      if [[ -n "${ssh_cmd}" ]]; then
        pout --debug "ssh_cmd" "${ssh_cmd}"
      else
        #{ Build ssh_path from host, user_name, and user_email
        if [[ -n "${host}" ]]; then
          ssh_path="${SSH_DIR}/${host}/${user_name}"
        else
          ssh_path="${SSH_DIR}/${user_name}_${user_email}"
        fi

        #{ Build ssh_cmd from ssh_path
        ssh_cmd="ssh -i ${ssh_path}"
      fi

      if [[ -n "${ssh_path}" ]]; then
        pout --debug "ssh_path" "${ssh_path}"
      else
        pout --warn "Profile skipped due to missing ssh_path: " "${_name}"
        return
      fi
    else
      pout --warn \
        "Profile skipped due to missing info: " \
        "${_name}"
      return
    fi

    # parse_gitconfig

  done
  IFS="${ifs}"

  #{ Cleanup variables
  unset profile host user_name user_email ssh_path ssh_cmd

  # for config_file in ${_git_profiles}; do
  #   echo "${config_file}"
  #   # parse_gitconfig "${config_file}"
  #   # generate_ssh_key \
  #   #   --host "${host}" \
  #   #   --name "${username}" \
  #   #   --email "${git_email}" \
  #   #   --path "${ssh_path}" \
  #   #   --cmd "${ssh_cmd}"
  # done
}

parse_gitconfig() {
  #{ Initialize variables
  ssh_path="" ssh_cmd="" host=""

  # while [[ "$#" -gt 0 ]]; do
  #   case "$1" in
  #   -P | --path) _path="$2" ;;
  #   -E | --env) _env="$2" ;;
  #   -N | --name) _name="$2" ;;
  #   *) ;;
  #   esac
  #   shift
  # done

  #{ Check for user group
  if grep -q '^\[user\]' "${_path}"; then
    pout --trace "Proceeding with git user profile: ${_name}"
  else
    pout --trace "Skipping profile due to missing user group: ${_name}"
    return
  fi

  #@Attempt to parse the host from the filename
  case "$(printf "%s" "${_path}" | tr '[:upper:]' '[:lower:]')" in
  *github*) host="github.com" ;;
  *gitlab*) host="gitlab.com" ;;
  *) host="" ;;
  esac
  pout --debug-or warn "Host" "${host}" "Parsed host from filename: ${host}"

  #{ Generate .env file, if necessary
  if [[ ! -f "${_env}" ]]; then
    pout --trace "Generating .env file for ${_name}"
    generate_ssh_env \
      -P "${_path}" -E "${_env}" -N "${_name}" -H "${host}"
  else
    case "${force:-}" in
    1 | true | on)
      pout --warn "Overriding existing .env file for ${_name}"
      generate_ssh_env \
        -P "${_path}" -E "${_env}" -N "${_name}" -H "${host}"
      ;;
    *)
      pout --trace "Proceeding with existing .env file for ${_name}"
      ;;
    esac
  fi

  #{ Read uncommented lines as key-value pairs and assign to shell variables
  if [[ -s "${_env}" ]]; then
    _tmp="${_env}.tmp.$$"
    grep -v '^[[:space:]]*#' "${_env}" >"${_tmp}"
    while IFS='=' read -r key value; do
      case "${key}" in
      name) user_name="${value}" ;;
      email) user_email="${value}" ;;
      ssh_cmd) ssh_cmd="${value}" ;;
      ssh_path) ssh_path="${value}" ;;
      host) host="${value}" ;;
      *) ;;
      esac
    done <"${_tmp}"
    rm -f "${_tmp}"

    #{ Check for required variables
    pout --debug-or warn "Host" "${host}" "Profile skipped due to missing host: ${_name}"
    pout --debug-or warn "Email" "${user_email}" "Profile skipped due to missing email: ${_name}"
    pout --debug-or warn "Name" "${user_name}" "Profile skipped due to missing name: ${_name}"

    if [[ -n "${ssh_cmd}" ]]; then
      pout --debug "ssh_cmd" "${ssh_cmd}"
    else
      #{ Build ssh_path from host, user_name, and user_email
      if [[ -n "${host}" ]]; then
        ssh_path="${SSH_DIR}/${host}/${user_name}"
      else
        ssh_path="${SSH_DIR}/${user_name}_${user_email}"
      fi

      #{ Build ssh_cmd from ssh_path
      ssh_cmd="ssh -i ${ssh_path}"
    fi

    if [[ -n "${ssh_path}" ]]; then
      pout --debug "ssh_path" "${ssh_path}"
    else
      pout --warn "Profile skipped due to missing ssh_path: " "${_name}"
      return
    fi
  else
    pout --warn \
      "Profile skipped due to missing info: " \
      "${_name}"
    return
  fi

  return

  #{ Attempt to extract the host from the filename
  local host
  case "$(printf "%s" "${_path}" | tr '[:upper:]' '[:lower:]')" in
  *github*) host="github.com" ;;
  *gitlab*) host="gitlab.com" ;;
  *) ;;
  esac

  #{ Attempt to extract the ssh_cmd from the profile
  local ssh_cmd ssh_path
  ssh_cmd="$(
    awk '
        /^\[core\]/ { in_core=1; next }
        /^\[/ { in_core=0 }
        in_core && /^[[:space:]]*sshCommand[[:space:]]*=/ {
          # Extract value after '=' and trim leading/trailing spaces
          sub(/^[[:space:]]*sshCommand[[:space:]]*=[[:space:]]*/, "")
          print
          exit
        }
      ' "${_path}"
  )"
  if [[ -n "${ssh_cmd:-}" ]]; then
    if [[ -n "${host:-}" ]]; then :; else
      #{ Attempt to extract the host from the ssh command
      case "$(printf "%s" "${ssh_cmd}" | tr '[:upper:]' '[:lower:]')" in
      *github*) host="github.com" ;;
      *gitlab*) host="gitlab.com" ;;
      *)
        pout --warn \
          "Skipping profile due to unknown host: " \
          "${_name}"
        return
        ;;
      esac
      pout --trace "    Host: " "${host}"
    fi
    #{ Extract the path from the ssh_cmd
    ssh_path="$(
      printf "%s" "${ssh_cmd}" |
        awk -F'-i ' '{if (NF>1) {split($2,a,"\""); print a[1]}}' |
        sed "s|~|${HOME}|g"
    )"
    pout --trace "SSH Path: " "${ssh_path}"
    pout --trace " SSH Cmd: " "${ssh_cmd}"
  else
    #{ If ssh_path is not set, set it to the default
    if [[ -n "${host}" ]]; then
      ssh_path="${SSH_DIR}/${host}/${user_name}"
    else
      ssh_path="${SSH_DIR}/${user_name}_${user_email}"
    fi

    #{ Generate the ssh_cmd
    ssh_cmd="ssh -i \"${ssh_path}\""
  fi

  unset _path _name _info user_email user_name ssh_path ssh_cmd
}

parse_ssh_info_from_file() {
  local _path
  _path="$1"

  awk -v HOME='${HOME}' '
    BEGIN {
        in_user = 0
        in_core = 0
        name = ""
        email = ""
        ssh_cmd = ""
        ssh_path = ""
    }
    /^\[/ {
        in_user = ($0 == "[user]")
        in_core = ($0 == "[core]")
        next
    }
    in_user && /^[[:space:]]*name[[:space:]]*=/ {
        val = $0
        sub(/.*=[[:space:]"]*/, "", val)
        sub(/[[:space:]"]*$/, "", val)
        name = val
        next
    }
    in_user && /^[[:space:]]*email[[:space:]]*=/ {
        val = $0
        sub(/.*=[[:space:]"]*/, "", val)
        sub(/[[:space:]"]*$/, "", val)
        email = val
        next
    }
    in_core && /^[[:space:]]*sshCommand[[:space:]]*=/ {
    val = $0
    sub(/.*=[[:space:]"]*/, "", val)
    sub(/[[:space:]"]*$/, "", val)
    ssh_cmd = val

    if (match(val, /-i[[:space:]]*[^[:space:]]+/)) {
        path = substr(val, RSTART + 2, RLENGTH - 2)

        # Trim spaces
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", path)

        # Remove quotes
        gsub(/^["'\'']|["'\'']$/, "", path)

        # Expand ~
        if (path ~ /^~\//) {
            path = HOME substr(path, 2)
        } else if (path == "~") {
            path = HOME
        }
        ssh_path = path
    }
    next

    }
    END {
        if (name != "")      print "name=\"" name "\""
        if (email != "")     print "email=\"" email "\""
        if (ssh_cmd != "")   print "ssh_cmd=\"" ssh_cmd "\""
        if (ssh_path != "")  print "ssh_path=\"" ssh_path "\""
    }
  ' "$_path"
}

generate_ssh_env() {
  local _path _name _env _host
  _path="" _name="" _env="" _host=""

  #{ Parse arguments
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -P | --path) _path="$2" ;;
    -N | --name) _name="$2" ;;
    -E | --env) _env="$2" ;;
    -H | --host) _host="$2" ;;
    *) ;;
    esac
    shift
  done

  # _name="${_name:-${_path##*/}}"

  # #{ Validate arguments
  # if [[ -n "${_path}" ]] && [[ -n "${_env}" ]]; then
  #   parse_command="$(parse_ssh_info_from_file "${_path}" >"${_env}")"
  #   if [[ "${parse_command}" -eq 0 ]]; then
  #     pout --trace "Generated .env file for ${_name:=}"
  #   else
  #     pout --warn "Failed to generate .env file for ${_name:=}"
  #   fi
  #   return
  # else
  #   pout --error "Missing required arguments for generating ssh .env file"
  # fi

}

generate_ssh_key() {
  local _host _user_name _user_email _ssh_path _ssh_cmd

  #{ Set default values
  _host="${host:-}"
  _user_name="${user_name:-}"
  _user_email="${user_email:-}"
  _ssh_path="${ssh_path:-}"
  _ssh_cmd="${ssh_cmd:-}"

  #{ Parse command-line options
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -h | --host) _host="$2" ;;
    -u | --username) _user_name="$2" ;;
    -e | --email) _user_email="$2" ;;
    -p | --path) _ssh_path="$2" ;;
    -c | --cmd) _ssh_cmd="$2" ;;
    *) ;;
    esac
    shift
  done

  echo "host: ${_host}"
  echo "user_name: ${_user_name}"
  echo "user_email: ${_user_email}"
  echo "ssh_path: ${_ssh_path}"
  echo "ssh_cmd: ${_ssh_cmd}"
  return 0

  #{ Ensure any tildes in the path are expanded
  if [[ "${key_path}" == *"~"* ]]; then
    key_path="${key_path/#\~/${HOME}}"
    key_path="${key_path//\~/${HOME}}"
    pout --trace "Expanded tilde in key path: ${key_path}"
  fi

  #{ Create directory for key if it doesn't exist
  local key_dir
  key_dir="$(dirname "${key_path}")"
  mkdir -p "${key_dir}"
  pout --info "Created directory: ${key_dir}"
  #{ Check if key already exists
  if [[ -f "${key_path}" && "${force}" != "true" ]]; then
    show_warning "SSH key already exists at ${key_path}. Use --force to regenerate."
    return 0
  elif [[ -f "${key_path}" && "${force}" == "true" ]]; then
    #{ Archive existing key
    local archive_dir="${key_dir}/archive"
    mkdir -p "${archive_dir}"
    pout --info "Created archive directory: ${archive_dir}"

    local timestamp
    timestamp="$(date +"%Y%m%d%H%M%S")"
    mv "${key_path}" "${archive_dir}/$(basename "${key_path}").${timestamp}"
    pout --info "Archived key: ${archive_dir}/$(basename "${key_path}").${timestamp}"

    if [[ -f "${key_path}.pub" ]]; then
      mv "${key_path}.pub" "${archive_dir}/$(basename "${key_path}").pub.${timestamp}"
      pout --info "Archived public key: ${archive_dir}/$(basename "${key_path}").pub.${timestamp}"
    fi
    pout --info "Archived existing key to ${archive_dir}"
  fi

  #{ Generate key comment with system information
  local key_comment
  key_comment=$(get_system_info "${email}")
  pout --info "Using SSH key comment: ${key_comment}"

  #{ Generate SSH key
  pout --info "Generating SSH key for ${username}@${host}"
  ssh-keygen -t ed25519 -a 100 -f "${key_path}" -C "${key_comment}" -N ""
  pout --info "Created key files: ${key_path} and ${key_path}.pub"

  #{ Add to SSH config
  printf "\nHost %s\n  User %s\n  HostName %s\n  IdentityFile %s\n" \
    "${host}" "${username}" "${host}" "${key_path}" >>"${SSH_CONFIG}"
  pout --info "Updated SSH config: ${SSH_CONFIG}"

  #{ Add key to SSH agent - handle commands separately
  #{ Start ssh-agent
  local agent_output
  agent_output=$(ssh-agent -s)
  eval "${agent_output}" >/dev/null
  pout --info "Started SSH agent"

  #{ Add key to agent
  ssh-add "${key_path}" >/dev/null || true
  pout --info "Added key to SSH agent"

  show_success "SSH key generated for ${username}@${host}"

  #{ Explicitly copy public key to clipboard
  local pub_key
  pub_key=$(cat "${key_path}.pub")
  copy_to_clipboard "${pub_key}"

  #{ Display the public key
  printf "\n%sPublic Key:%s\n" "${YELLOW}" "${RESET}"
  cat "${key_path}.pub"
  printf "\n"

  #{ Prompt user to add key to Git host if in interactive mode
  if [[ "${non_interactive}" != "true" ]]; then
    show_instruction "Please add this SSH key to your ${host} account:"
    show_instruction "1. Login to ${host}"
    show_instruction "2. Navigate to SSH keys settings"
    show_instruction "3. Add a new SSH key"
    show_instruction "4. Paste the key (should be in your clipboard)"
    show_instruction "5. Save the key"

    show_prompt "Press Enter when you've added the key to your ${host} account, or Ctrl+C to exit"
    read -r

    #{ Validate the key by testing connection
    validate_ssh_connection "${host}" "${username}" "${key_path}"
  fi
}

#{ Function to get system information for SSH key comment
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

  #{ Combine hostname, OS, and email
  printf "%s-%s-%s" "${hostname}" "${os_info}" "${email}"
}

#{ Function to copy text to clipboard
copy_to_clipboard() {
  local text="$1"
  local success=false

  #{ Try different clipboard commands based on available tools
  if command -v xclip &>/dev/null; then
    echo -n "${text}" | xclip -selection clipboard && success=true
  elif command -v xsel &>/dev/null; then
    echo -n "${text}" | xsel --clipboard --input && success=true
  elif command -v pbcopy &>/dev/null; then
    echo -n "${text}" | pbcopy && success=true
  elif command -v clip.exe &>/dev/null; then
    #{ For Windows/WSL
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

#{ Function to parse Git config file and extract SSH information
parse_git_config() {
  local config_file="$1"
  local filename
  filename="$(basename "${config_file}")"

  #{ Extract host and username from filename (format: host_username.gitconfig)
  local host username
  IFS='_' read -r host username <<<"$(basename "${filename}" .gitconfig)"

  #{ Read git user information from config - avoid command substitution masking
  local git_name git_email ssh_path

  #{ Handle each command separately to avoid masking return values
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

  #{ Normalize host (add .com if missing)
  if ! printf "%s" "${host}" | grep -q '\.'; then
    host="${host}.com"
  fi

  #{ Only output the variable assignments - no debug info
  printf "host=%q\n" "${host}"
  printf "username=%q\n" "${username}"
  printf "git_name=%q\n" "${git_name}"
  printf "git_email=%q\n" "${git_email}"
  printf "ssh_path=%q\n" "${ssh_path}"
}

#{ Function to validate SSH connection
validate_ssh_connection() {
  local host="$1"
  local username="$2"
  local key_path="$3"
  local ssh_check_cmd="ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=accept-new -T -i \"${key_path}\" git@\"${host}\""

  pout --info "Validating SSH connection to ${host}..."
  pout --info "> ${ssh_check_cmd}"

  #{ Try the connection with auto-accepting host keys
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

#{ Function to list available profiles
list_profiles() {
  if [[ ! -d "${GIT_PROFILES_DIR}" ]]; then
    show_error "Git profiles directory not found: ${GIT_PROFILES_DIR}"
    exit 1
  fi

  printf "%s\n" "${BOLD}Available Git Profiles:${RESET}"

  #{ Find gitconfig files
  local configs=()

  #{ Handle find separately to avoid masking return values
  local find_output
  find_output=$(find "${GIT_PROFILES_DIR}" -name "*.gitconfig" -type f || true)

  if [[ -z "${find_output}" ]]; then
    printf "  No profiles found\n"
    return
  fi

  #{ Read find output into array
  mapfile -t configs <<<"${find_output}"

  for config_file in "${configs[@]}"; do
    local filename
    filename="$(basename "${config_file}")"
    printf "  - %s\n" "${filename}"
  done
}

fetch_info__os() {
  CMD_NIXOS_VERSION="$(command -v nixos-version 2>/dev/null)"
  CMD_POWERSHELL="$(command -v powershell 2>/dev/null)"
  CMD_PWSH="$(command -v pwsh 2>/dev/null)"
  CMD_POWERSHELL="${CMD_PWSH:-"${CMD_POWERSHELL:-}"}"
  CMD_CMD="$(command -v cmd.exe 2>/dev/null)"

  #{ Retrieve bulk system info (lowercase)
  system_info() {
    if uname -a >/dev/null 2>&1; then
      uname -a
    elif [[ -f /proc/version ]]; then
      cat /proc/version 2>/dev/null || true
    else
      printf ""
    fi | tr '[:upper:]' '[:lower:]' || true
  }

  is_wsl() {
    system_info | grep -q "microsoft"
  }

  nixos_version() {
    if [[ -x "${CMD_NIXOS_VERSION:-}" ]]; then
      #{ Print the OS name
      printf "%s" "NixOS"

      #{ Extract the major and minor part of the version
      _ver="$(nixos-version | cut -d. -f1,2)"

      #{ Append the version
      printf "_%s" "${_ver}"

      return 0
    else
      return 1
    fi
  }

  windows_version() {
    #{ Print the OS name
    printf "%s" "Windows"

    #{ Append the version
    if [[ -x "${CMD_POWERSHELL:-}" ]]; then
      _ver="$(
        "${CMD_POWERSHELL}" -NoProfile -Command "[System.Environment]::OSVersion.Version.ToString()" \
          2>/dev/null | tr -d '\r\n'
      )"
      if [[ -z "${_ver}" ]]; then :; else printf "_%s" "${_ver}"; fi
    elif [[ -x "${CMD_CMD}" ]]; then
      "${CMD_CMD}" /c ver | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1
    else
      printf "11"
    fi
  }

  macos_version() {
    printf "MacOS_"
    sw_vers -productVersion 2>/dev/null | cut -d. -f1,2
  }

  os_type() {
    uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf ""
  }

  os_ver() {
    if uname -r >/dev/null 2>&1; then
      printf "_%s" "$(uname -r)"
    else
      printf ""
    fi
  }

  #{ Detect OS
  case "$(system_info)" in
  *linux*)
    #{ Try nixos_version and check its status
    os_ver="$(nixos_version)"
    status=$?
    if [[ $status -eq 0 ]]; then :; else os_ver="Linux$(os_ver)"; fi

    # WSL detection
    is_wsl
    status=$?
    if [[ "$status" -eq 0 ]]; then
      printf "_WSL"
    fi

    printf "%s%s" "${os_ver}" "${wsl}"
    ;;
  *msys* | *ming* | *cygwin*)
    win_ver="$(windows_version)"
    status=$?
    if [[ "$status" -eq 0 ]]; then
      printf "%s" "$win_ver"
    else
      printf "Windows%s" "$(os_ver)"
    fi
    ;;
  *darwin*)
    mac_ver="$(macos_version)"
    status=$?
    if [[ "$status" -eq 0 ]]; then
      printf "%s" "$mac_ver"
    else
      printf "MacOS%s" "$(os_ver)"
    fi
    ;;
  *)
    printf "%s%s" "$(os_type)" "$(os_ver)"
    ;;
  esac

  fetch_info__user() {
    printf "%s" "${USER:-"${USERNAME:-""}"}"
  }

  fetch_info__host() {
    uname -n || hostname || printf ""
  }

  fetch_info__all() {
    printf "%s@%s on %s" \
      "$(fetch_info__user)" "$(fetch_info__host)" "$(fetch_info__os)"
  }

  if [[ "$#" -lt 1 ]]; then
    fetch_info__all
  else
    while [[ "$#" -ge 1 ]]; do
      case "$1" in
      --os) fetch_info__os ;;
      --user) fetch_info__user ;;
      *) fetch_info__all ;;
      esac
      shift
    done
  fi
}

pout() {
  #{ Initialize variables
  _clr=
  _opt=
  _opt_arg=
  _key=
  _value=
  _msg=

  #{ Set verbosity
  case "${trace:-0}" in 1 | on | true) verbosity=5 ;; *) ;; esac
  case "${debug:-0}" in 1 | on | true) verbosity=4 ;; *) ;; esac
  case "${info:-0}" in 1 | on | true) verbosity=3 ;; *) ;; esac
  case "${warn:-0}" in 1 | on | true) verbosity=2 ;; *) ;; esac
  case "${error:-0}" in 1 | on | true) verbosity=1 ;; *) ;; esac
  case "${quiet:-0}" in 1 | on | true) verbosity=0 ;; *) ;; esac
  case "${verbosity:-0}" in
  quiet | 0) verbosity=0 ;;
  error | 1) verbosity=1 ;;
  warn | 2) verbosity=2 ;;
  info | 3) verbosity=3 ;;
  debug | 4) verbosity=4 ;;
  trace | 5) verbosity=5 ;;
  *) ;;
  esac

  #{ Parse arguments
  case "$1" in
  --trim)
    shift
    _msg="$(printf "%s" "$*" | awk '{$1=$1; print}')"
    ;;
  -t | --trace)
    if [[ "${verbosity}" -lt 5 ]]; then :; else
      _clr="${MAGENTA}"
      _opt="TRACE"
      shift
      _msg="$*"
    fi
    ;;
  --debug)
    if [[ "${verbosity}" -lt 4 ]]; then return; else
      _clr="${CYAN}"
      _opt="DEBUG"
      shift
    fi

    _key="$1"
    if [[ -z "$2" ]]; then _val="undefined"; else
      shift
      _val="$*"
    fi
    _msg="${_key}: ${_val}"
    ;;
  --debug-or)
    #TODO: Add error handling
    shift
    _opt_arg="--${1}"
    shift
    _key="$1"
    _val="$2"

    if [[ -n "${_val}" ]]; then
      pout --debug "${_key}" "${_val}"
    else
      if [[ "$#" -le 2 ]]; then :; else
        shift
        pout "${_opt_arg}" "$*"
      fi
    fi
    ;;
  -i | --info)
    if [[ "${verbosity}" -lt 3 ]]; then :; else
      _clr="${BLUE}"
      _opt=" INFO"
      shift
      _msg="$*"
    fi
    ;;
  -w | --warn*)
    if [[ "${verbosity}" -lt 1 ]]; then :; else
      _clr="${YELLOW}"
      _opt=" WARN"
      shift
      _msg="$*"
    fi
    ;;
  -e | --error)
    if [[ "${verbosity}" -lt 1 ]]; then :; else
      _clr="${RED}"
      _opt="ERROR"
      shift
      _msg="$*"
    fi
    ;;
  -s | --success)
    _clr="${GREEN}"
    _opt="Success"
    shift
    _msg="$*"
    ;;
  -p | --prompt)
    _clr="${MAGENTA}"
    _opt="Prompt"
    shift
    _msg="$*"
    ;;
  -v | --version)
    shift
    _msg="$(printf "%s v%s\n" "${APP_NAME}" "${APP_VERSION}")"
    ;;
  -h | --help)
    _msg="$(
      printf "%s v%s\n\n" "${APP_NAME}" "${APP_VERSION}"
      printf "Usage: %s [OPTIONS]\n\n" "${APP_NAME}"
      printf "Automatically configures SSH for Git based on your dotfiles.\n\n"
      printf "Options:\n"
      printf "  -h, --help      Show this help message and exit\n"
      printf "  -v, --version   Show version information and exit\n"
      printf "  -d, --dir DIR   Set custom dotfiles directory (default: %s)\n" "${DOTS}"
      printf "  -f, --force     Force regeneration of existing keys\n"
      printf "  -l, --list      List available profiles\n"
      printf "  -y, --yes       Non-interactive mode (no prompts)\n\n"
      printf "Examples:\n"
      printf "  %s\n" "${APP_NAME}"
      printf "  %s --dir ~/my-dotfiles\n" "${APP_NAME}"
      printf "  %s --force\n" "${APP_NAME}"
      printf "  %s --yes\n" "${APP_NAME}"
    )"
    ;;
  *)
    _msg="$*"
    ;;
  esac

  #{ Print message
  if [[ -z "${_msg:-}" ]]; then :; elif
    [[ -z ${_clr:-} ]] || [[ -z ${_opt:-} ]]
  then
    printf "%b\n" "${_msg}"
  else
    printf "${_clr}%s /> ${RESET}%b\n" "${_opt}" "${_msg}"
  fi

  #{ Reset variables
  unset _clr _reset _opt _msg
}

#{ Run the script
main "$@"
