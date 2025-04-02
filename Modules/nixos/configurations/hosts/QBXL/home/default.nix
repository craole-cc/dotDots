# { dots, paths, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bac";
    # extraSpecialArgs = { inherit dots paths; };
    users.craole.imports = [
      ./packages
    ];
  };
}
