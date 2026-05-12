{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = ["systems.nix" "sources.nix"];
  ignore = ["openclaw.nix"];
}
