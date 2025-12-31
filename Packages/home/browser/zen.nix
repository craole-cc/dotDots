# Packages/home/browser/zen/default.nix
{
  lib,
  user,
  pkgs,
  homeModules,
  ...
}: let
  # variant = user.applications.browser.variant or "default";
  variant = "twilight";
  zenModule = homeModules.zen-browser.${variant} or {};
in {
  imports = [zenModule];

  config = {
    programs.zen-browser = {
      enable = true;
      # ... your config
    };
  };
}
