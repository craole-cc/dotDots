{
  host,
  lib,
  user,
  lix,
  mkMerge,
  ...
}: {
  settings = mkMerge [
    (import ./io.nix {inherit user host lib lix;})
    (import ./startup.nix)
    # (import ./core.nix)
    # (import ./rules.nix {inherit lib;})
  ];
}
