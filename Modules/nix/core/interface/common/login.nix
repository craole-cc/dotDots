{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.${dom};

  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.types) bool nullOr str;
  inherit (lix.modules.core.services) mkServices;

  # Pure data seeds — only referenced in option `default =` expressions,
  # never consulted in the config block.
  user = host.users.data.primary or {};
  iface = host.interface or {};
in {
  options.${top}.${dom} = {
    enable = mkEnableOption dom // {default = true;};

    windowManager = mkOption {
      description = ''
        Window manager to enable. Drives hyprland/niri program modules,
        iio-niri sensor integration, and the computed display session name.
      '';
      default = iface.windowManager or null;
      defaultText = literalExpression "host.interface.windowManager or null";
      example = literalExpression ''"hyprland"'';
      type = nullOr str;
    };

    desktopEnvironment = mkOption {
      description = ''
        Desktop environment to enable (COSMIC, GNOME, Plasma). Takes
        precedence over `windowManager` for session naming when both are set.
      '';
      default = iface.desktopEnvironment or null;
      defaultText = literalExpression "host.interface.desktopEnvironment or null";
      example = literalExpression ''"gnome"'';
      type = nullOr str;
    };

    displayProtocol = mkOption {
      description = ''
        Display protocol forwarded to managers that support both modes
        (GDM, SDDM). Defaults to Wayland.
      '';
      default = iface.displayProtocol or "wayland";
      defaultText = literalExpression ''host.interface.displayProtocol or "wayland"'';
      example = literalExpression ''"x11"'';
      type = str;
    };

    displayManager = mkOption {
      description = ''
        Display manager (greeter) to enable. Recognised values: `"gdm"`,
        `"sddm"`, `"ly"`, `"cosmic-greeter"`, `"dms-greeter"`. Setting
        `panel = "dms-shell"` overrides this with the DMS greeter on
        Hyprland and Niri.
      '';
      default = iface.displayManager or null;
      defaultText = literalExpression "host.interface.displayManager or null";
      example = literalExpression ''"sddm"'';
      type = nullOr str;
    };

    panel = mkOption {
      description = ''
        Panel or shell package name. `"dms-shell"` activates the DMS
        greeter on Hyprland and Niri, suppressing other display managers.
      '';
      default = iface.panel or (user.interface.bar or null);
      defaultText = literalExpression "host.interface.panel or (host.users.data.primary.interface.bar or null)";
      example = literalExpression ''"dms-shell"'';
      type = nullOr str;
    };

    defaultSession = mkOption {
      description = ''
        Explicit display-manager session name. When null the session is
        derived from `windowManager`, then `desktopEnvironment`, with a
        `hyprland-uwsm` override when `config.programs.hyprland.withUWSM`
        is true.
      '';
      default = iface.defaultSession or null;
      defaultText = literalExpression "host.interface.defaultSession or null";
      example = literalExpression ''"hyprland-uwsm"'';
      type = nullOr str;
    };

    autoLogin = mkOption {
      description = "Whether to enable automatic login for the primary user.";
      default = user.autoLogin or false;
      defaultText = literalExpression "host.users.data.primary.autoLogin or false";
      type = bool;
    };

    autoLoginUser = mkOption {
      description = ''
        Username for automatic login. Defaults to the primary user's name.
      '';
      default = user.name or null;
      defaultText = literalExpression "host.users.data.primary.name or null";
      example = literalExpression ''"craole"'';
      type = nullOr str;
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      (mkServices {
        inherit config;
        inherit (cfg)
          windowManager
          desktopEnvironment
          displayProtocol
          displayManager
          defaultSession
          panel
          autoLogin
          autoLoginUser
          ;
      })
    ]
  );
}
