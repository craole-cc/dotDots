{
  programs.topgrade = {
    enable = true;
    settings = {
      misc = {
        assume_yes = true;
        # disable = ["nix"];
        set_title = false;
        cleanup = true;
      };
      commands = {
        "Run garbage collection on Nix store" = "nix-collect-garbage";
      };
    };
  };
}
