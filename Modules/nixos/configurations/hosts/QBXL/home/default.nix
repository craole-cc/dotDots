{ config, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bac";
    # extraSpecialArgs = { inherit (config) dots; };
    users.craole.imports = [
      ./packages
    ];
  };
}
