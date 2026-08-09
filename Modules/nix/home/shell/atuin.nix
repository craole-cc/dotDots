{
  config,
  top,
  ...
}: let
  isEnabled = pkg: config.programs.${pkg}.enable;
in {
  programs.atuin = {
    enable = config.${top}.inputs.applications.utilities.atuin.enable;
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
  ${top}.output.programs.atuin = config.programs.atuin;
}
