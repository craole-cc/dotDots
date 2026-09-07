{
  pkgs,
  lix,
  sources,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.transformation) replaceStrings toUpper;
  inherit (pkgs) writeScriptBin writeShellScript writeText;

  description = "WhatsApp Gateway";
  src = sources.hermes-agent;
  dom = "hermes";
  mod = "whatsapp";
  name = "${dom}-${mod}";
  envPrefix = toUpper (replaceStrings ["-"] ["_"] name);

  gateway = writeText "${name}-gateway.py" (readFile ./gateway.py);
  bridgeSetup = writeShellScript "${name}-bridge-setup" (readFile ./bridge.sh);
  pair = writeShellScript "${name}-pair" (readFile ./shell.sh);
  command = writeScriptBin name ''
    #!/bin/sh
    set -eu
    sh ${bridgeSetup}
    exec sh ${pair}
  '';

  env' = {
    "${envPrefix}_BRIDGE_SETUP" = escapeShellArg bridgeSetup;
    "${envPrefix}_BRIDGE_SRC" = escapeShellArg (src + "/scripts/whatsapp-bridge");
    "${envPrefix}_GATEWAY_PY" = escapeShellArg gateway;
  };

  packages = with pkgs;
    [nodejs python3]
    ++ [command];

  helpEntries = [
    ["${name}" "Pair/configure the WhatsApp bridge"]
  ];

  shellHook = ''
    export HERMES_WHATSAPP_BRIDGE_DIR="''${HERMES_WHATSAPP_BRIDGE_DIR:-$HERMES_HOME/whatsapp/bridge}"
  '';
in {
  inherit description helpEntries packages shellHook;
  env = env';
}
