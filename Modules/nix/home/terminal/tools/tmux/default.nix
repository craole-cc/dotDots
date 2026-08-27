#TODO: The modules need to be options, not hardcoded
{
  osConfig ? null,
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
          if osConfig != null
          then
            (osConfig.services.openssh.enable or false)
            || (osConfig.services.tailscale.enable or false)
          else false
        );
    };
    outputs = {inherit (resolved) programs home;};
  }
