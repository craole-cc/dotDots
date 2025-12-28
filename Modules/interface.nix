{
  host,
  pkgs,
  lib,
  lix,
  inputs,
  ...
}: let
  inherit (host.paths) dots;
  inherit (lix.applications.resolution) editors browsers terminals launchers bars;
  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;
  user = host.users.data.primary or {};
  wm = host.interface.windowManager or null;
  de = host.interface.desktopEnvironment or null;
  dp = host.interface.displayProtocol or null;
  dm = host.interface.displayManager or null;
  # useDms = wm == "niri" || wm == "hyprland";
  useDms = false;
in {
  programs = {
    bash = {
      enable = (
        ((host.interface.shell or null) == "bash")
        || (isIn "bash" (host.users.data.primary.shells or []))
      );
      blesh.enable = true;
      undistractMe.enable = true;
    };

    hyprland = {
      enable = wm == "hyprland";
      withUWSM = true;
    };

    niri = {
      enable = wm == "niri";
    };

    starship = {
      enable = host.interface.prompt or null == "starship";
    };

    xwayland.enable = true;
  };

  services = {
    iio-niri.enable = wm == "niri";

    desktopManager = {
      cosmic = {
        enable = de == "cosmic";
        showExcludedPkgsWarning = false;
      };

      gnome = {
        enable = de == "gnome";
      };

      plasma6 = {
        enable = de == "plasma";
      };
    };

    displayManager = {
      autoLogin = {
        enable = user.autoLogin or false;
        user = user.name or null;
      };

      cosmic-greeter = {
        enable = de == "cosmic" && !useDms;
      };

      dms-greeter = {
        enable = useDms;
      };

      gdm = {
        enable = dm == "gdm" && !useDms;
        wayland = dp == "wayland";
      };

      sddm = {
        enable = dm == "sddm" && !useDms;
        wayland.enable = dp == "wayland";
      };

      ly = {
        enable = dm == "ly";
      };
    };
  };

  systemd.services = mkIf (dm == "gdm") {
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
  };
}
