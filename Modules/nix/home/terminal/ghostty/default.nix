#TODO: The modules need to be options, not hardcoded
{
  config,
  lix,
  user,
  pkgs,
  ...
}: let
  dom = "terminal";
  mod = "ghostty";

  inherit (lix.modules.construction) mkConfig mkMerge;
  inherit (lix.options.construction) mkEnableOption;
  inherit (lix.applications.generators) userApplicationConfig;

  resolved = userApplicationConfig {
    inherit user pkgs config dom mod;
    extraProgramConfig = mkMerge [
      (import ./general.nix)
      (import ./input.nix)
      (import ./themes.nix)
    ];
    debug = false;
  };
in
  mkConfig {
    inherit config dom mod;
    predicate = resolved.enable;
    options = {
      enable = mkEnableOption mod // {default = resolved.enable;};
    };
    outputs = {inherit (resolved) programs home;};
  }
