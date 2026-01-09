# Packages/home/common/darkman.nix
{
  nixosConfig,
  host,
  lib,
  pkgs,
  config,
  user,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.strings) hasPrefix;
  inherit (pkgs) writeShellScript;

  #~@ Location
  loc = user.localization or host.localization or nixosConfig.location or {};
  lat = loc.latitude or null;
  lng = loc.longitude or null;
  usegeoclue = (loc.provider or "manual") == "geoclue2";

  #~@ Style
  style = user.interface.style or host.interface.style or {};
  switch = style.autoSwitch or false;

  #~@ Paths
  wallpapers = let
    path =
      user.paths.wallpapers or
      host.paths.wallpapers or
      "Pictures/Wallpapers";
  in
    if hasPrefix "/" path
    then path
    else "${config.home.homeDirectory}/${path}";

  dots = host.paths.dots or null;
  userApi = "${dots}/API/users/${user.name}/default.nix";

  #~@ Enable condition
  enable =
    switch
    && (lat != null)
    && (lng != null)
    && (dots != null);

  #~@ Mode script generator
  mkModeScript = mode: let
    sd = "${pkgs.sd}/bin/sd";
    ln = "${pkgs.coreutils}/bin/ln";
    dbus = "${pkgs.dbus}/bin/dbus-send";
    dconf = "${pkgs.dconf}/bin/dconf";
    # hypr = "${pkgs.hyprland}/bin/hyprctl";
    note = "${pkgs.libnotify}/bin/notify-send";

    newWallpaper = "${wallpapers}/${mode}-wallpaper";
    oldWallpaper = "${wallpapers}/current-wallpaper";

    #> Portal mode: 1 = prefer dark, 2 = prefer light
    portalMode =
      if mode == "dark"
      then "1"
      else "2";
  in
    writeShellScript "darkman-${mode}-mode" ''
      set -euo pipefail

      #> Update theme mode in user configuration
      ${sd} 'current = "(dark|light)"' 'current = "${mode}"' "${userApi}"

      #> Update the freedesktop portal setting
      ${dbus} --session --dest=org.freedesktop.portal.Desktop \
        --type=method_call /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.ReadOne \
        string:'org.freedesktop.appearance' string:'color-scheme' \
        uint32:${portalMode} 2>/dev/null || true

      #> Update GTK/Qt theming preference
      ${dconf} write /org/gnome/desktop/interface/color-scheme "'prefer-${mode}'" || true

      #> Update wallpaper
      if [ -L "${oldWallpaper}" ] || [ -e "${newWallpaper}" ]; then
        ${ln} -sf "${newWallpaper}" "${oldWallpaper}"
      fi

      #> Notify
      ${note} "Theme Switched" "Switched to ${mode} mode" -t 2000 || true
    '';
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
    darkModeScripts.nixos-theme = mkModeScript "dark";
    lightModeScripts.nixos-theme = mkModeScript "light";
  };
}
