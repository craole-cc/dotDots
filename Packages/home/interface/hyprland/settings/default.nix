{
  host,
  lib,
  ...
}: {
  settings = lib.mkMerge [
    (import ./output.nix {inherit host lib;})
    (import ./input.nix {inherit host lib;})
    # // (import ./environment.nix {inherit host lib;})
    # // (import ./startup.nix)
    (import ./core.nix)
    (import ./rules.nix {inherit lib;})
  ];
}
