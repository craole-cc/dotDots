#TODO: The modules need to be options, not hardcoded
{
  config,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig mkMerge;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.applications.generators) userApplicationConfig;

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "core";
    mod = "ghostty";
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    extraProgramConfig = mkMerge [
      (import ./general.nix)
      (import ./input.nix)
      (import ./themes.nix)
    ];
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = resolved.enable;
    };
    outputs = {
      inherit (resolved) programs home;

      # Ghostty owns its light/dark theme pair and follows the desktop color
      # scheme. Stylix's Ghostty target replaces `settings.theme` with its
      # static generated theme, which prevents runtime light/dark switching.
      stylix.targets.ghostty.enable = false;
    };
  }
