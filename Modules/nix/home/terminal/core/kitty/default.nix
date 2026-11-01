{
  config,
  lix,
  pkgs,
  style,
  user,
  ...
}: let
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.strings.construction) optionalString;
  inherit (lix.options.construction) mkEnable;
  inherit (context) wantsDmsShell;
  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "emulators";
    mod = "kitty";
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    extraProgramConfig = {
      settings = {
        background_opacity = style.opacity.terminal.dark;
        dynamic_background_opacity = true;
        copy_on_select = "clipboard";
        confirm_os_window_close = 0;
        remember_window_size = false;
      };

      # DMS owns the generated color files. Home Manager only includes them
      # when DMS is the active shell; without DMS Kitty keeps its own defaults.
      extraConfig = optionalString wantsDmsShell.condition ''
        include dank-tabs.conf
        include dank-theme.conf
        include dotdots-opacity.conf
      '';
    };
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = resolved.enable;
        description = "Kitty Terminal Emulator";
      };
    };
    outputs = {inherit (resolved) programs home;};
  }
