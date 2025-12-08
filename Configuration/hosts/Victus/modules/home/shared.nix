{
  inputs ? {},
  lib,
  pkgs,
  config,
  icons,
  host,
  lix,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lix.trivial) isNotEmpty;

  hmUsers = filterAttrs (_: user: (user.role != "service")) host.users;
in {
  home-manager = mkIf (isNotEmpty hmUsers) {
    backupFileExtension = "backup";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        lix
        host
        icons
        ;
    };
    # sharedModules = [../themes/icons];
    users = import ./user.nix;
  };
}
