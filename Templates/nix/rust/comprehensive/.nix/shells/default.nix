{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  # priority = [
  #   "core.nix"
  #   "data.nix"
  # ];
  ignore = [
    "scripts.nix"
    "config.nix"
  ];
}
