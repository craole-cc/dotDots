{
  packages,
  env,
  print,
  ...
}: {
  shellHook = ''
    ${print.table {
      columns = ["Command" "Description"];
      rows =
        map
        (entry: with entry; [command description])
        packages.helpEntries;
    }}

    if [ -t 1 ]; then
      printf '%s\n' "API URL: ${env.get "API_URL"}"
      if ! ${env.tag "status"} > /dev/null 2>&1; then
        ${env.tag "up"}
      fi
    fi
  '';
}
