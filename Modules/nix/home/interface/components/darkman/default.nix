{
  host,
  lib,
  paths,
  pkgs,
  user,
  nixosConfig,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (nixosConfig.location) latitude longitude provider;
  inherit (pkgs) replaceVarsWith;

  #~@ Location
  lat = latitude;
  lng = longitude;
  usegeoclue = provider == "geoclue2";

  #~@ Enable condition
  style = user.interface.style or host.interface.style or {};
  enable = style.autoSwitch or true;

  toggle = polarity:
    replaceVarsWith {
      src = ./toggle.sh;
      replacements = {
        cfgApi = "${paths.api.user}";
        cfgPolarity = polarity;
        cmdDconf = "${pkgs.dconf}/bin/dconf";
        cmdNotify = "${pkgs.libnotify}/bin/notify-send";
        cmdSd = "${pkgs.sd}/bin/sd";
        cmdWallman = "${paths.wallpapers.manager}/bin/wallman";
      };
      name = "nixos-theme";
      isExecutable = true;
    };
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {
      inherit lat lng usegeoclue;
      dbusserver = true;
      portal = true;
    };
    darkModeScripts.nixos-theme = toggle "dark";
    lightModeScripts.nixos-theme = toggle "light";
  };
}
