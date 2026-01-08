{
  host,
  lib,
  user,
  lix,
  ...
}: {
  settings = lib.mkMerge [
    (import ./io.nix {inherit user host lib lix;})
    (import ./startup.nix)
    # (import ./core.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix)
  ];
}
