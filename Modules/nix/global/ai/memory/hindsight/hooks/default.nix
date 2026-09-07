{
  env,
  helpEntries,
  lib,
  lix,
  pkgs,
  print,
  title,
  ...
}: let
  inherit (pkgs) writeScriptBin;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.strings.predicates) hasPrefix;
  inherit (lix.lists.transformation) filter;
  inherit (lib) tag get prefix;

  headline = print.title title;

  entries = let
    internal = [
      {
        command = tag "help";
        description = "Show this help";
      }
    ];
    external = helpEntries;
  in {
    merged = internal ++ external;
    inherit internal external;
  };

  tables = {
    help = print.table {
      columns = ["Command" "Description"];
      rows = map (entry: with entry; [command description]) entries.merged;
    };

    vars = print.table {
      columns = ["Variable" "Value"];
      rows = map (name: [name "\${${name}:-unset}"]) (
        filter (hasPrefix "${prefix}_") (attrNames env)
      );
    };
  };

  helpContent = ''
    #!/bin/sh
    set -eu
    ${headline}
    ${tables.help}
    ${tables.vars}
  '';
in {
  shellHook = ''
    export HINDSIGHT_SECRETS_FILE="''${HINDSIGHT_SECRETS_FILE:-''${PRIVATE:-$HOME/Private}/hindsight.env}"
    export HINDSIGHT_API_PORT="''${HINDSIGHT_API_PORT:-8888}"
    export HINDSIGHT_MCP_PORT="''${HINDSIGHT_MCP_PORT:-9999}"
    export HINDSIGHT_UI_PORT="''${HINDSIGHT_UI_PORT:-8889}"

    if [ -t 1 ]; then
      ${headline}
      ${tables.help}
      printf '%s\n' "API URL: ${get "API_URL"}"
    fi
  '';
  packages = [(writeScriptBin (tag "help") helpContent)];
  helpEntries = entries.internal;
}
