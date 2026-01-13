{
  host,
  lib,
  user,
  lix,
  ...
}: {
  settings = lib.mkMerge [
    (import ./core.nix {inherit user host lib;})
    (import ./io.nix {inherit user host lib lix;})
    # (import ./startup.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix {inherit lib;})
  ];
}
