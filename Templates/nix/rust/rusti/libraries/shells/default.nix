{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  ignore = ["meta.nix" "config.nix"];
}
