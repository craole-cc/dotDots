{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.lists) optionals;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "tools";
    mod = "yazi";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = user.applications.utilities.yazi.enable or false;
    };
    outputs = {
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
      };
      home.packages = with pkgs.yaziPlugins; optionals pkgs.stdenv.hostPlatform.isDarwin [mactag];
    };
  }
