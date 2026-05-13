{lib, ...}:
lib.assembly.importLibs {
  inherit lib;
  path = ./.;
  priority = ["core" "modules"];
  # priority = [
  #   # "core.nix"
  #   # "data.nix"
  #   # "config.nix"
  # ];
}
