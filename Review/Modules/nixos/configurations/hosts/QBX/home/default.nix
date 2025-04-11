{
  imports = [
    <home-manager/nixos>
    ./users
  ];

  home-manager = {
    backupFileExtension = "BaC";
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
