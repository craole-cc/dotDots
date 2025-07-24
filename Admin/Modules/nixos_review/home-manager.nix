{
  lib,
  inputs,
  host,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) genAttrs attrNames;
  isDarwin = builtins.match ".*darwin" host.platform != null;
  allowHomeManager = host.allowHomeManager or true;
  homeModules =
    if allowHomeManager
    then [
      (with inputs.nixosHome;
        if isDarwin
        then darwinModules.home-manager
        else nixosModules.home-manager)
    ]
    else [];
in {
  imports = homeModules;
  config = mkIf allowHomeManager {
    home-manager = {
      backupFileExtension = host.backupFileExtension or "backup";
      # extraSpecialArgs = specialArgs;
      useGlobalPkgs = true;
      useUserPackages = true;
      users = genAttrs (attrNames host.userConfigs) (
        username: {osConfig, ...}: {
          home = {inherit (osConfig.system) stateVersion;};
          programs.home-manager.enable = true;
        }
      );
      sharedModules = [];
    };
  };
}
# if (host.allowHomeManager or true) then
#   [
#     (with inputs.nixosHome; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
#     {
# home-manager = {
#   backupFileExtension = host.backupFileExtension or "backup";
#   # extraSpecialArgs = specialArgs;
#   useGlobalPkgs = true;
#   useUserPackages = true;
#   users = genAttrs (attrNames host.userConfigs) (
#     username:
#     { osConfig, ... }:
#     {
#       home = { inherit (osConfig.system) stateVersion; };
#       programs.home-manager.enable = true;
#     }
#   );
#   sharedModules = [ ];
# };
#     }
#   ]
# else
#   [ ]

