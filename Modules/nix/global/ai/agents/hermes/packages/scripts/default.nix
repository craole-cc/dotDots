{
  lix,
  pkgs,
  print,
  tools,
  env,
  prepare-hermes-gateway ? "",
  helpEntries ? [],
  ...
}: let
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (pkgs) writeScriptBin;
  inherit (tools) names commands descriptions;

  render = replacements: path:
    replaceStrings (attrNames replacements)
    (map (key: replacements.${key}) (attrNames replacements))
    (readFile path);

  ownEntries = [
    ["start" "Start the Hermes gateway (--no-confirm to skip prompt)"]
    ["hermes-gateway" "Run the composed Hermes messaging gateway"]
    ["hermes-gateway-service" "Print the canonical systemd user unit"]
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

  gateway = writeScriptBin "hermes-gateway" (render {
      "@hermes_env_sh@" = env.HERMES_ENV_SH;
      "@prepare_hermes_gateway@" = prepare-hermes-gateway;
      "@hermes_exe@" = tools.default.exe;
    }
    ./gateway.sh);

  gatewayService = writeScriptBin "hermes-gateway-service" (render {
      "@gateway_exe@" = "${gateway}/bin/hermes-gateway";
    }
    ./gateway-service.sh);

  scripts = {
    hermes-gateway = gateway;
    hermes-gateway-service = gatewayService;
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
    packages = with scripts; [hermes-gateway hermes-gateway-service hermes-help hermes-tui start];
  }
