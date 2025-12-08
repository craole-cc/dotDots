{ config, policies, ... }:
let
  isAllowed = policies.dev;
  isEnabled = pkg: config.programs.${pkg}.enable;
in
{
  programs.atuin = {
    enable = isAllowed;
    daemon.enable = isAllowed;
    enableBashIntegration = isEnabled "bash";
    enableNushellIntegration = isEnabled "nushell";
    enableFishIntegration = isEnabled "fish";
    enableZshIntegration = isEnabled "zsh";
    settings = import ./settings.nix;
  };
  imports = [
    # ./settings.nix
    # ./themes.nix
  ];
}
