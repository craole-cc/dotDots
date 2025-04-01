{
  imports = [
    (import "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz"}/nixos")
  ];

  home-manager = {
    useGlobalPkgs = true;
    users.craole.imports = [ ./packages ];
  };
}
