{
  host,
  lib,
  user,
  lix,
  apps,
  ...
}: {
  settings = lib.mkMerge [
    (import ./core.nix)
    (import ./io.nix {inherit user apps host lib lix;})
    # (import ./startup.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix {inherit apps;})
  ];
}
