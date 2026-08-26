{lix, ...}: let
  inherit (lix.filesystem.access) readFile;
  prepare = readFile ./runtime.sh;
in {
  gatewayFragment = prepare;
  prepare-discord-gateway = prepare;
}
