{ lib }:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
}
