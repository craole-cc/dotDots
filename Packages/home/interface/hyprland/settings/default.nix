{
  host,
  lib,
  user,
  lix,
  ...
}: {
  settings = lib.mkMerge [
    (import ./core.nix)
    (import ./io.nix {inherit user host lib lix;})
    # (import ./startup.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix)
  ];
}
