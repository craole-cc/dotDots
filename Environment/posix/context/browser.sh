#! /bin/sh
# shellcheck disable=SC2034,SC2154,SC1091

#|-> Browser
case "${SYS_TYPE}" in
Windows)
  browser_id=$(
    reg query "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" |
      awk '/ProgId/ {print $3}'
  )
  browser_cmd=$(reg query "HKCR\\${browser_id}\\shell\\open\\command" | awk -F'    ' '/REG_SZ/ {print $4}')
  browser_path=$(printf "%s" "${browser_cmd}" | sed -n 's/.*"\(.*\)".*/\1/p')
  browser="${browser_paths:-"$(browser-edge --set 2>/dev/null)"}"
  ;;
*)
  browser_path="xdg-open"
  ;;
esac
manage_env --set --var BROWSER --val "${browser_path:-"firefox"}"
