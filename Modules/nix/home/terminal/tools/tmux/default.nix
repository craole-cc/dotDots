#TODO: The modules need to be options, not hardcoded
{
  osConfig,
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
    sub = "tools";
    mod = "tmux";
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    extraProgramConfig = mkMerge [
      (import ./plugins.nix)
    ];
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition =
        resolved.enable
        || (
          with osConfig.services;
            (openssh.enable or false)
            || (tailscale.enable or false)
        );
    };
    outputs = {inherit (resolved) programs home;};
  }
