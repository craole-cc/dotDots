{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "core";
    mod = "kitty";
  };

  dmsEnabled = context.wantsDmsShell.condition;

  resolved = userApplicationConfig {
    inherit context user pkgs;
    extraProgramConfig = {
      settings.copy_on_select = "clipboard";

      # DMS owns the generated color files. Home Manager only includes them
      # when DMS is the active shell; without DMS Kitty keeps its own defaults.
      extraConfig = lib.optionalString dmsEnabled ''
        include dank-tabs.conf
        include dank-theme.conf
      '';
    };
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = resolved.enable;
    };
    outputs = {inherit (resolved) programs home;};
  }
