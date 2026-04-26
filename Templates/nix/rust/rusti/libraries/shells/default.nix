{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = ["core"];
  ignore = ["combined.nix" "meta.nix" "config.nix"];
}
