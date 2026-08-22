args: let
  inherit (args) lix;
  inherit (lix.filesystem.access) readFile;
  # "''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"; # TODO: This is WRONG. shared env needs to define XDG_STATE_HOME
in {
  prepare-whatsapp-bridge = ''
    export HERMES_WHATSAPP_BRIDGE_SRC=${bridge}
    export HERMES_WHATSAPP_BRIDGE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"
    export HERMES_WHATSAPP_GATEWAY_PY=${gateway}
    ${readFile ./bridge.sh}
  '';
}
