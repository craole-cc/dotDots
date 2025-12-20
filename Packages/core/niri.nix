{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.user.interface.windowManager.niri;
  inherit (lib) mkEnableOption mkOption types mkIf;
in {
  options.user.interface.windowManager.niri = {
    enable = mkEnableOption "Niri window manager";

    package = mkOption {
      type = types.package;
      default = inputs.niri.packages.${pkgs.system}.niri-unstable;
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
    # Don't use overlay - get package directly from flake
    environment.systemPackages = let
      # Get the flake package directly
      niriPkg = inputs.niri.packages.${pkgs.system}.niri-unstable.overrideAttrs (old: {
        # Skip tests if they're failing
        doCheck = false;
        checkPhase = "";
      });
    in
      [
        niriPkg
        pkgs.wl-clipboard
        pkgs.wayland-utils
        pkgs.libsecret
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
