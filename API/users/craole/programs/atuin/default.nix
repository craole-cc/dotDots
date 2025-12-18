{
  user,
  config,
  lib,
  ...
}: let
  app = "atuin";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
  isEnabled = pkg: config.programs.${pkg}.enable; #TODO: Use lix
in {
  programs.${app} =
    {
      enable = isAllowed;
      daemon.enable = true;
      enableBashIntegration = isEnabled "bash";
      enableNushellIntegration = isEnabled "nushell";
      enableFishIntegration = isEnabled "fish";
      enableZshIntegration = isEnabled "zsh";
    }
    // import ./settings.nix;
}
