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

      # greetd's PAM stack includes the login stack. Enabling the NixOS GNOME
      # Keyring service wires pam_gnome_keyring into that login path so the
      # user's login keyring is unlocked by the greeter password instead of
      # starting an unrelated daemon later in the graphical session.
      services.gnome.gnome-keyring.enable = lib.mkIf cfg.enable true;
    };
  }
