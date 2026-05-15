{
  config,
  lib,
  user,
  ...
}: let
  app = "quickshell";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app} =
    {
      enable = isAllowed;
      enableBashIntegration = config.programs.bash.enable;
      enableNushellIntegration = config.programs.nushell.enable;
    }
    // import ./settings.nix;
}
