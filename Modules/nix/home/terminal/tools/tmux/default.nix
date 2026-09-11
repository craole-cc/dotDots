{
  osConfig ? null,
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig mkMerge;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "tools";
    mod = "tmux";
  };
  inherit (context) cfg;

  remoteSession =
    if osConfig != null
    then
      (osConfig.services.openssh.enable or false)
      || (osConfig.services.tailscale.enable or false)
    else false;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = (user.applications.utilities.tmux.enable or false) || remoteSession;
    };
    outputs.programs.tmux = mkMerge [
      {inherit (cfg) enable;}
      (import ./plugins.nix)
    ];
  }
