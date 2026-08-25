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
    ["configure-hindsight" "Configure this profile for Victus external Hindsight"]
    ["start" "Start the Hermes gateway (--no-confirm to skip prompt)"]
    ["hermes-help" "Show this help"]
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
    configure-hindsight = writeScriptBin "configure-hindsight" (readFile ./configure-hindsight.sh);
    hermes-help = writeScriptBin "hermes-help" helpContent;
    hermes-tui = writeScriptBin "hermes-tui" ''
      #!/bin/sh
      set -eu
      exec hermes --tui "$@"
    '';
    start = writeScriptBin "start" (readFile ./start.sh);
  };
in
  scripts
  // {
    packages = with scripts; [configure-hindsight hermes-help hermes-tui start];
  }
