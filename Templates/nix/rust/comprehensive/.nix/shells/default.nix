{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = [
    "core.nix"
    "data.nix"
    "config.nix"
  ];
  ignore = ["scripts.nix"];
}
