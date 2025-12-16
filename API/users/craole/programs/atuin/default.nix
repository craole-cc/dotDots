{
  user,
  config,
  lib,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user) enable;
  app = "atuin";
  isAllowed = elem app enable;
  isEnabled = pkg: config.programs.${pkg}.enable;
in {
  programs.${app} = {
    enable = isAllowed;
    daemon.enable = isAllowed;
    enableBashIntegration = isEnabled "bash";
    enableNushellIntegration = isEnabled "nushell";
    enableFishIntegration = isEnabled "fish";
    enableZshIntegration = isEnabled "zsh";
  };
  imports = [
    ./settings.nix
    # ./themes.nix
  ];
}
