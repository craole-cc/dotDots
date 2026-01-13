{
  host,
  lib,
  user,
  lix,
  apps,
  ...
}: {
  settings = lib.mkMerge [
    (import ./core.nix {inherit user apps host lib;})
    (import ./io.nix {inherit user apps host lib lix;})
    # (import ./startup.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix {inherit lib;})
  ];
}
