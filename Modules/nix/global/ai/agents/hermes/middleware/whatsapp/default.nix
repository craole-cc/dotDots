{
  pkgs,
  lix,
  tools,
  env,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  description = "Hermes Agent Gateway - WhatsApp";

  env' = {
    HERMES_WHATSAPP_BRIDGE_DIR = env.XDG_STATE_HOME + "/hermes/whatsapp-bridge";
    HERMES_WHATSAPP_BRIDGE_SETUP = escapeShellArg ./bridge.sh;
    HERMES_WHATSAPP_BRIDGE_SRC = escapeShellArg (tools.default.paths.store + "/scripts/whatsapp-bridge");
    HERMES_WHATSAPP_GATEWAY_PY = escapeShellArg ./gateway.py;
  };

  packages = with pkgs; [
    nodejs
    python3
  ];

  shellHook = ''sh ${env'.HERMES_WHATSAPP_BRIDGE_SETUP}'';
in {
  inherit description packages shellHook;
  env = env';
}
