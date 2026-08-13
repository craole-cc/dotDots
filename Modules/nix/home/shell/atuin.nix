{
  config,
  lib,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  isEnabled = pkg: config.programs.${pkg}.enable;
  payload = {
    programs.atuin = {
      enable = config.${top}.resolved.applications.utilities.atuin.enable;
      daemon.enable = true;
      enableBashIntegration = isEnabled "bash";
      enableNushellIntegration = isEnabled "nushell";
      enableFishIntegration = isEnabled "fish";
      enableZshIntegration = isEnabled "zsh";
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://api.atuin.sh";
        search_mode = "prefix";
      };
    };
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
  });
}
