{lib}:
lib.assembly.importAttrs {
  inherit lib;
  path = ./.;
  priority=["systems.nix" "sources.nix" "binaries.nix"];
}
