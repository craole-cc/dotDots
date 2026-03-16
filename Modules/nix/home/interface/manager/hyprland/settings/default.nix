{
  apps,
  host,
  lib,
  lix,
  keyboard,
  mkMerge,
  withRules ? true,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  settings = mkMerge [
    (import ./core.nix {inherit apps keyboard;})
    (import ./io.nix {inherit apps host lix lib keyboard;})
    (mkIf withRules (import ./rules {
      inherit
        apps
        keyboard
        lib
        mkMerge
        ;
    }))
  ];
}
