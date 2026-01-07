{
  host,
  lib,
  lix,
  mkMerge,
  ...
}: {
  settings = mkMerge [
    (import ./io.nix {inherit host lib lix;})
    # (import ./startup.nix)
    (import ./core.nix)
    (import ./rules.nix {inherit lib;})
  ];
}
