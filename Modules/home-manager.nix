{
  lib,
  inputs,
  host,
  ...
}:
let
  inherit (lib.attrsets) genAttrs attrNames;
  isDarwin = builtins.match ".*darwin" host.platform != null;
in
if (host.allowHomeManager or true) then
  [
    (with inputs.nixosHome; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
    {
      home-manager = {
        backupFileExtension = host.backupFileExtension or "backup";
        # extraSpecialArgs = specialArgs;
        useGlobalPkgs = true;
        useUserPackages = true;
        users = genAttrs (attrNames host.userConfigs) (
          username:
          { osConfig, ... }:
          {
            home = { inherit (osConfig.system) stateVersion; };
            programs.home-manager.enable = true;
          }
        );
        sharedModules = [ ];
      };
    }
  ]
else
  [ ]
