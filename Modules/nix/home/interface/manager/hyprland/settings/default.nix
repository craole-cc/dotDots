# settings/default.nix
{
  apps,
  host,
  lib,
  lix,
  keyboard,
  mkMerge,
  withRules ? true,
  ...
}: {
  settings = mkMerge [
    (import ./core.nix {inherit apps keyboard;})
    (import ./io.nix {inherit apps host lix lib keyboard;})
    (lib.mkIf withRules (import ./rules.nix {inherit lib;}))
    (import ./workspaces.nix {inherit lib apps keyboard;})
  ];
}
