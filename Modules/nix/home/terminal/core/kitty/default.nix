{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.attrsets.predicates) waylandEnabled;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "core";
    mod = "kitty";
  };
  inherit (context) cfg;

  hasWayland = waylandEnabled {
    inherit config;
    interface = user.interface or {};
  };
  dmsEnabled = context.wantsDmsShell.condition;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = hasWayland;
    };

    outputs.programs.kitty = {
      inherit (cfg) enable;
      package = pkgs.kitty;

      # DMS owns the generated color files. Home Manager only includes them
      # when DMS is the active shell; without DMS Kitty keeps its own defaults.
      extraConfig = lib.optionalString dmsEnabled ''
        include dank-tabs.conf
        include dank-theme.conf
      '';
    };
  }
