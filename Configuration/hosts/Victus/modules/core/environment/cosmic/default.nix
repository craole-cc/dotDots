{
  host,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  enable = host.interface.desktopEnvironment == "cosmic";
in {
  imports = [
    (import ./packages.nix {inherit mkIf enable pkgs;})
    (import ./services.nix {inherit mkIf enable;})
  ];
}
