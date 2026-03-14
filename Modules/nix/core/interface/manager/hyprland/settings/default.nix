{
  apps,
  host,
  lib,
  lix,
  keyboard,
  mkMerge,
  ...
}: {
  settings = mkMerge [
    (import ./core.nix {inherit apps keyboard;})
    (import ./io.nix {inherit apps host lix lib keyboard;})
    # (import ./startup.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix {inherit lib apps keyboard;})
  ];
}
