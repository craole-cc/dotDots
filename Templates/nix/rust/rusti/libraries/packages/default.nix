{lib}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = ["systems.nix"];
  ignore = ["ai.nix" "openclaw.nix" "rust.nix"];
}
