{
  user,
  config,
  lix,
  ...
}: let
  app = "atuin";
  inherit (lix.lists.predicates) isIn;
  inherit (user.applications) allowed;
  isAllowed = isIn app allowed;
  isEnabled = pkg: config.programs.${pkg}.enable;
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
