{
  config,
  lix,
  pkgs,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "common";
    mod = "portal";
  };
  inherit (context) cfg;
  inherit (lix.lists.transformation) unique;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) listOf nullOr;
  inherit (lix.types.primitives) package;

  registry = {
    packages = with pkgs; {
      default = [xdg-desktop-portal-gtk];
      hyprland = [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      niri = [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
    };

    portals = let
      default = with registry;
        if checks.hyprland
        then packages.hyprland
        else if checks.niri
        then packages.niri
        else packages.default;
      overrides = cfg.portals or default;
      extra = cfg.extraPortals or [];
    in {
      inherit default overrides extra;
      final = unique (overrides ++ extra);
    };

    checks = with cfg; {
      autoSwitch = config.${context.top}.resolved.interface.style.autoSwitch or true;
      darkman = preferDarkman;
      hyprland =
        (windowManager == "hyprland")
        || config.programs.hyprland.enable or false
        || config.wayland.windowManager.hyprland.enable or false;

      niri =
        (windowManager == "niri")
        || config.programs.niri.enable or false;

      windowManager = config.${context.top}.resolved.interface.windowManager or null;
    };

    settings = with registry.checks; {
      "org.freedesktop.impl.portal.Settings" =
        if darkman && autoSwitch
        then ["darkman"]
        else ["gtk"];
    };
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Whether to enable XDG desktop portal configuration.";
        condition = true;
      };
      portals = mkOption {
        description = "Override the list of extra portals";
        inherit (registry.portals) default;
        type = nullOr (listOf package);
      };
      extraPortals = mkOption {
        description = "Additional portals to add on top of the defaults.";
        default = [];
        type = nullOr (listOf package);
      };
      preferDarkman = mkEnable {
        description = "Prefer darkman for the Settings portal when auto theme switching is enabled.";
        condition = true;
      };
    };
    outputs = with registry; {
      xdg.portal = mkIf cfg.enable {
        enable = true;
        extraPortals = portals.final;
        config = with checks; {
          common.default = ["*"];
          hyprland = mkIf hyprland (
            {default = ["hyprland" "gtk"];} // settings
          );
          niri = mkIf niri (
            {default = ["gnome" "gtk"];} // settings
          );
        };
      };
    };
  }
