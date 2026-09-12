{
  config,
  host,
  lib,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "common";
    mod = "greeter";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) str;

  interface = host.interface or {};
  selected = interface.displayManager or null;
  compositor = interface.compositor.window or interface.compositor.desktop or null;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = selected == "dms-greeter";
        defaultText = literalExpression ''host.interface.displayManager == "dms-greeter"'';
      };

      compositor = mkOption {
        description = "Compositor used by the DMS greeter.";
        default = compositor;
        defaultText = literalExpression "host.interface.compositor.window or host.interface.compositor.desktop or null";
        type = nullOr str;
      };
    };

    outputs = {
      services.displayManager.dms-greeter = {
        enable = cfg.enable;
        compositor.name = cfg.compositor;
      };

      # oo7 is a cross-desktop Freedesktop Secret Service provider. Its NixOS
      # module enables pam_oo7 on the login stack, and greetd delegates its
      # auth/password/session handling to that stack, so the user's keyring is
      # unlocked by the greeter password without depending on GNOME Keyring.
      services.oo7.enable = lib.mkIf cfg.enable true;
    };
  }
