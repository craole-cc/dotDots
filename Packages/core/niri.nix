# In your niri module
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.user.interface.windowManager.niri;
  inherit (lib) mkEnableOption mkOption types mkIf mkDefault;

  # Get the flake's niri-unstable package
  niriFlakePkg = inputs.niri.packages.${pkgs.system}.niri-unstable;
in {
  options.user.interface.windowManager.niri = {
    enable = mkEnableOption "Niri window manager";

    package = mkOption {
      type = types.package;
      default = niriFlakePkg;
      description = "Niri package to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Niri configuration settings";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages for Niri";
    };
  };

  config = mkIf cfg.enable {
    # Use the flake package explicitly
    environment.systemPackages = with pkgs;
      [
        niriFlakePkg # Use flake package directly
        wl-clipboard
        wayland-utils
        libsecret
      ]
      ++ cfg.extraPackages;

    # Environment variables
    environment.variables = {
      NIXOS_OZONE_WL = "1";
      XDG_CURRENT_DESKTOP = "niri";
    };

    # Enable necessary services
    services.dbus.enable = true;
    security.polkit.enable = true;

    # Pipewire for audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # XDG portal integration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
      config = {
        common.default = ["wlr" "gtk"];
        niri.default = ["wlr" "gtk"];
      };
    };
  };
}
