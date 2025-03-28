{
  perSystem.treefmt = {
    programs = {
      #| Nix
      rustfmt = {
        enable = true;
        priority = 1;
      };
      taplo = {
        enable = true;
        priority = 1;
      };
    };
  };
}
