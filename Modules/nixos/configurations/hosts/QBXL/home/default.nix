{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.craole.imports = [
      ./packages
    ];
  };
}
