# interface/common/login.nix
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
  useDms =
    cfg.windowShell
    == "dms"
    && (cfg.windowManager == "niri" || cfg.windowManager == "hyprland");
in {
  config = mkIf (cfg.displayManager != null) {
    services.displayManager = {
      defaultSession = cfg.defaultSession;
      autoLogin = mkIf (user.autoLogin or false) {
        enable = true;
        user = user.name or null;
      };
      sddm = mkIf (cfg.displayManager == "sddm") {
        enable = true;
        wayland.enable = cfg.displayProtocol == "wayland";
      };
      gdm = mkIf (cfg.displayManager == "gdm") {
        enable = true;
        wayland = cfg.displayProtocol == "wayland";
      };
      cosmic-greeter.enable = cfg.displayManager == "cosmic-greeter" && !useDms;
      dms-greeter.enable = useDms || cfg.displayManager == "dms-greeter";
      ly.enable = cfg.displayManager == "ly";
    };
    systemd.services = mkIf (cfg.displayManager == "gdm") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };
  };
}
