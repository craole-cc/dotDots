{
  pkgs,
  lix,
  tools,
  XDG_STATE_HOME,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  description = "Hermes Agent";

  env = {
    HERMES_WHATSAPP_BRIDGE_DIR = XDG_STATE_HOME + "/hermes/whatsapp-bridge";
    HERMES_WHATSAPP_BRIDGE_SETUP = escapeShellArg ./bridge.sh;
    HERMES_WHATSAPP_BRIDGE_SRC = escapeShellArg (tools.default.paths.store + "/scripts/whatsapp-bridge");
    HERMES_WHATSAPP_GATEWAY_PY = escapeShellArg ./gateway.py;
  };

  packages = with pkgs; [
    nodejs
    # python3
  ];

  shellHook = "";
in {inherit description env packages shellHook;}
