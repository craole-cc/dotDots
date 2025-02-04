{ config, lib, ... }:
with lib;
with config.dots.lib.get.host;
with interface;
with login;
with fonts.console;

{
  config.services = {
    kmscon = {
      enable = true;
      autologinUser = mkIf (autoLogin) user;
      # autologinUser = mkIf (isMinimal && autoLogin) user;
      extraConfig = "font-size=${toString size}";
      extraOptions = "--term xterm-256color";
      fonts = sets;
    };

    displayManager = mkIf (!isMinimal) {
      enable = true;
      autoLogin = {
        enable = autoLogin;
        inherit user;
      };
      sddm = {
        enable = true;
        wayland.enable = isWayland;
      };
    };
  };
}
