{
  user,
  config,
  lix,
  ...
}: let
  app = "atuin";
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn app (user.applications.allowed or []);
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
