{
  env,
  lib,
  lix,
  packages,
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
  entries = {
    help =
      packages.helpEntries
      ++ [
        {
          command = tag "help";
          description = "Show this help";
        }
      ];
  };

  tables = {
    help = print.table {
      columns = ["Command" "Description"];
      rows =
        map
        (entry: with entry; [command description])
        entries.help;
    };

    vars = print.table {
      columns = ["Variable" "Value"];
      rows = map (name: [name "\${${name}:-unset}"]) (
        filter
        (suffix: hasPrefix "${prefix}" suffix)
        (attrNames env)
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
    ${headline}
    ${tables.help}

    if [ -t 1 ]; then
      printf '%s\n' "API URL: ${get "API_URL"}"
      if ! ${tag "status"} > /dev/null 2>&1; then
        ${tag "up"}
      fi
    fi
  '';
  packages = [(writeScriptBin (tag "help") helpContent)];
  helpEntries = entries.help;
}
