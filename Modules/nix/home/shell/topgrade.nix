{config, top, ...}: {
  programs.topgrade = {
    enable = config.${top}.inputs.applications.utilities.topgrade.enable;
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
  ${top}.output.programs.topgrade = config.programs.topgrade;
}
