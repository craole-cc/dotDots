{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = ["systems.nix" "sources.nix" "binaries.nix"];
  ignore = ["openclaw.nix"];
}
