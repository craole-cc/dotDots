{
  pkgs,
  prepare-hermes-messaging,
  prepare-whatsapp-bridge,
  ...
}: let
  inherit (pkgs) writeScriptBin;
  pre = "hermes";
in {
  "${pre}-dev" = writeScriptBin "${pre}-dev" ''
    #!/bin/sh
    set -eu
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    exec hermes --profile dev "$@"
  '';
}
