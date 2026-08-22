#!/usr/bin/env bash

#{ Define thefile paths
conf_file="${SHELL_HOME:-}/inputrc"
home_file="${HOME}/.inputrc"

#{ Ensure the source file exist.
[[ -f ${conf_file} ]] || {
  printf "Error: Config inputrc file not found."
  return 1
}

#{ Copy the config file if the home file doesn't exist
[[ -f ${home_file} ]] || {
  printf \
    "Home inputrc file not found.\nCopying it from %s\n" \
    "${conf_file}"
  cp "${conf_file}" "${home_file}"
  return 0
}

#{ Compare modification times and update the older of the two files
if [ "${conf_file}" -nt "${home_file}" ]; then
  #{ Config file is newer, copy to home
  printf "Config inputrc is newer. Copying to home..."
  cp -f "${conf_file}" "${home_file}"
  printf "Sync complete."
elif [ "${home_file}" -ot "${conf_file}" ]; then
  #{ Home file is newer, copy to config
  printf "Home inputrc is newer. Copying to config..."
  cp -f "${home_file}" "${conf_file}"
  printf "Sync complete."
else
  :
fi
