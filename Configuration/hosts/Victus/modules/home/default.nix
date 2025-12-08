{
  lib,
  icons,
  host,
  users,
  lix,
  funk,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) filterAttrs;

  args = {
    users = filterAttrs (_: user: (user.role != "service")) users;
    inherit
      lix
      lib
      host
      icons
      funk
      mkIf
      ;
  };
in {
  home-manager = mkIf (args.users != {}) {
    backupFileExtension = "backup";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = args;
    # sharedModules = [../themes/icons];
    users = import ./user.nix {inherit args;};
  };
}
