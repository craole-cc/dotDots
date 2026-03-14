{
  config,
  host,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;

  user = host.users.data.primary or {};
  useDms = cfg.bar == "dms" && (cfg.wm == "niri" || cfg.wm == "hyprland");
in {
  config = mkIf (cfg.uiShell != null) {
    services.displayManager = {
      defaultSession = cfg.uiShell;

      autoLogin = mkIf (user.autoLogin or false) {
        enable = true;
        user = user.name or null;
      };

      sddm = mkIf (cfg.dm == "sddm") {
        enable = true;
        wayland.enable = cfg.dp == "wayland";
      };

      gdm = mkIf (cfg.dm == "gdm") {
        enable = true;
        wayland = cfg.dp == "wayland";
      };

      cosmic-greeter.enable = cfg.dm == "cosmic-greeter" && !useDms;
      dms-greeter.enable = useDms || cfg.dm == "dms-greeter";
      ly.enable = cfg.dm == "ly";
    };

    systemd.services = mkIf (cfg.dm == "gdm") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };
  };
}
