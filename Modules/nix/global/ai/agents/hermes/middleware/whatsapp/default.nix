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
  inherit (pkgs) writeScriptBin;
  description = "WhatsApp Gateway";
  src = sources.hermes-agent;
  dom = "hermes";
  mod = "whatsapp";
  name = "${dom}-${mod}";
  envPrefix = toUpper (replaceStrings ["-"] ["_"] name);

  env' = {
    "${envPrefix}_BRIDGE_DIR" = env.XDG_STATE_HOME + "/hermes/whatsapp-bridge";
    "${envPrefix}_BRIDGE_SETUP" = escapeShellArg ./bridge.sh;
    "${envPrefix}_BRIDGE_SRC" = escapeShellArg (src + "/scripts/whatsapp-bridge");
    "${envPrefix}_GATEWAY_PY" = escapeShellArg ./gateway.py;
  };

  packages = with pkgs;
    [nodejs python3]
    ++ [(writeScriptBin name (readFile ./shell.sh))];

  helpEntries = [
    ["${name}" "Pair/configure the WhatsApp bridge"]
  ];

  shellHook = ''sh ${env'."${envPrefix}_BRIDGE_SETUP"}'';
in {
  inherit description helpEntries packages shellHook;
  env = env';
}
