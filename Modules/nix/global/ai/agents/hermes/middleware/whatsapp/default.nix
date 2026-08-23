{
  pkgs,
  lix,
  sources,
  env,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.filesystem.access) readFile;
  inherit (pkgs) writeScriptBin;
  description = "WhatsApp Gateway";
  name = "hermes-whatsapp";

  env' = {
    HERMES_WHATSAPP_BRIDGE_DIR = env.XDG_STATE_HOME + "/hermes/whatsapp-bridge";
    HERMES_WHATSAPP_BRIDGE_SETUP = escapeShellArg ./bridge.sh;
    HERMES_WHATSAPP_BRIDGE_SRC = escapeShellArg (sources.hermes-agent + "/scripts/whatsapp-bridge");
    HERMES_WHATSAPP_GATEWAY_PY = escapeShellArg ./gateway.py;
  };

  # "${name}" = writeScriptBin name (readFile ./shell.sh);

  packages = with pkgs;
    [nodejs python3]
    ++ [(writeScriptBin name (readFile ./shell.sh))];

  shellHook = ''sh ${env'.HERMES_WHATSAPP_BRIDGE_SETUP}'';
in {
  inherit description packages shellHook;
  env = env';
}
