{config, top, ...}: {
  programs.topgrade = {
    enable = config.${top}.applications.utilities.topgrade.enable;
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
