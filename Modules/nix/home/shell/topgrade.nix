{config, lib, lix, top, ...}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {

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
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
