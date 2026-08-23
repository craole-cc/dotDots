{
  lix,
  pkgs,
  print,
  tools,
  helpEntries ? [],
  ...
}: let
  inherit (pkgs) writeScriptBin;
  inherit (lix.filesystem.access) readFile;
  inherit (tools) names commands descriptions;

  ownEntries = [
    ["start" "Start the Hermes gateway (--no-confirm to skip prompt)"]
    ["show-help" "Show this help"]
  ];

  helpContent = ''
    #!/bin/sh
    set -eu
    ${print.title "Hermes Agent"}
    ${print.table {
      columns = ["Command" "Description"];
      rows =
        (map (name: [
            (commands.${name} or name)
            (descriptions.${name} or "?")
          ])
          names)
        ++ ownEntries
        ++ helpEntries;
    }}

    ${print.table {
      columns = ["Variable" "Value"];
      rows = [
        ["HERMES_HOME" "\${HERMES_HOME:-unset}"]
        ["HERMES_GATEWAY_CFG" "\${HERMES_GATEWAY_CFG:-unset}"]
        ["AUTO_START" "\${AUTO_START:-unset}"]
        ["STARTUP_TIMEOUT" "\${STARTUP_TIMEOUT:-unset}"]
      ];
    }}
  '';

  scripts = {
    start = writeScriptBin "start" (readFile ./start.sh);
    show-help = writeScriptBin "show-help" helpContent;
  };
in
  scripts
  // {
    packages = with scripts; [start show-help];
  }
