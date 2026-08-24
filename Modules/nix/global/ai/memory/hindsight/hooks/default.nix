{
  packages,
  env,
  ...
}: let
  inherit (packages) helpTable;
  apiUrl = env."${env.prefix}_API_URL";
in {
  shellHook = ''
    ${helpTable}

    if [ -t 1 ]; then
      printf '%s\n' "API URL: ${apiUrl}"
      if ! ${env.name}-status > /dev/null 2>&1; then
        ${env.name}-up
      fi
    fi
  '';
}
