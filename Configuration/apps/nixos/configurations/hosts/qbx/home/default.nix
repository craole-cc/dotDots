{
  imports = [
    <home-manager/nixos>
    ./users
  ];

  home-manager = {
    backupFileExtension = "pop";
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
