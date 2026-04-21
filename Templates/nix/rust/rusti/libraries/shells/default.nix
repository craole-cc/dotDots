{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  ignore = ["ai.nix" "meta.nix" "config.nix"];
}
