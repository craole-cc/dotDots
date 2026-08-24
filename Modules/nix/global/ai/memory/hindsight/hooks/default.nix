{
  packages,
  print,
  env,
  ...
}: let
  inherit (packages) descriptions names;
in {
  shellHook = ''
    ${print.title "Hindsight"}
    ${print.table {
      columns = ["Command" "Description"];
      rows = map (name: [name (descriptions.${name} or "?")]) names;
    }}

    if [ -t 1 ]; then
      printf '%s\n' "API URL: ${env.HINDSIGHT_API_URL}"
    fi
  '';
}
