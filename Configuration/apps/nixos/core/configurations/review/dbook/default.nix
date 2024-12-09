{
  imports = [
    ./configuration.nix
  ];

  DOTS = {
    users = {
      craole.enable = true;
      # qyatt.enable = true;
    };
  };
}
