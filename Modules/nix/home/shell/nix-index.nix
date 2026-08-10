{config, lib, lix, top, ...}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {

      programs.nix-index = {
        enable = config.${top}.resolved.applications.utilities.nix-index.enable;
        enableBashIntegration = config.programs.bash.enable;
        enableZshIntegration = config.programs.zsh.enable;
        enableFishIntegration = config.programs.fish.enable;
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
