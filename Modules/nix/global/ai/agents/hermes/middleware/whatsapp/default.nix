args: let
  inherit (args) lix;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.transformation) escapeShellArg;

  HERMES_WHATSAPP_BRIDGE_SRC = escapeShellArg (HERMES_HOME + "/scripts/whatsapp-bridge");
  HERMES_WHATSAPP_BRIDGE_DIR = "";
  # "''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"; # TODO: This is WRONG. shared env needs to define XDG_STATE_HOME
  HERMES_WHATSAPP_GATEWAY_PY = escapeShellArg "${./gateway.py}";
  env = {
    inherit
      HERMES_WHATSAPP_BRIDGE_SRC
      HERMES_WHATSAPP_BRIDGE_DIR
      HERMES_WHATSAPP_GATEWAY_PY
      ;
  };
in {
  prepare-whatsapp-bridge = ''
    export HERMES_WHATSAPP_BRIDGE_SRC=${bridge}
    export HERMES_WHATSAPP_BRIDGE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"
    export HERMES_WHATSAPP_GATEWAY_PY=${gateway}
    ${readFile ./bridge.sh}
  '';
}
