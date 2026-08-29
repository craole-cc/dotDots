{
  pkgs,
  lix,
  sources,
  env,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.transformation) replaceStrings toUpper;
  inherit (pkgs) writeScriptBin writeShellScript;
  description = "WhatsApp Gateway";
  src = sources.hermes-agent;
  dom = "hermes";
  mod = "whatsapp";
  name = "${dom}-${mod}";
  envPrefix = toUpper (replaceStrings ["-"] ["_"] name);
  bridgeSetup = writeShellScript "${name}-bridge-setup" (readFile ./bridge.sh);

  env' = {
    "${envPrefix}_BRIDGE_DIR" = env.XDG_STATE_HOME + "/hermes/whatsapp-bridge";
    "${envPrefix}_BRIDGE_SETUP" = escapeShellArg bridgeSetup;
    "${envPrefix}_BRIDGE_SRC" = escapeShellArg (src + "/scripts/whatsapp-bridge");
    "${envPrefix}_GATEWAY_PY" = escapeShellArg ./gateway.py;
  };

  packages = with pkgs;
    [nodejs python3]
    ++ [(writeScriptBin name (readFile ./shell.sh))];

  helpEntries = [
    ["${name}" "Pair/configure the WhatsApp bridge"]
  ];

  shellHook = ''
    if [ -t 1 ]; then
      sh ${env'."${envPrefix}_BRIDGE_SETUP"}
    fi
  '';
in {
  inherit description helpEntries packages shellHook;
  env = env';
}
