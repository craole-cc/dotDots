{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  ignore = ["combined.nix" "meta.nix" ];
}
