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
  inherit (lib.strings) hasPrefix hasInfix toLower;
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
    nh = "${pkgs.nh}/bin/nh";
    dbus = "${pkgs.dbus}/bin/dbus-send";
    dconf = "${pkgs.dconf}/bin/dconf write";
    hypr = "${pkgs.hyprland}/bin/hyprctl";
    note = "${pkgs.libnotify}/bin/notify-send";

    newWallpaper = "${wallpapers}/${mode}-wallpaper";
    oldWallpaper = "${wallpapers}/current-wallpaper";
    theme = toLower (style.theme.${mode} or "");
  in
    writeShellScript "darkman-${mode}-mode" ''
      set -euo pipefail

      #> Update theme mode in user configuration
      ${sd} 'current = "(dark|light)"' 'current = "${mode}"' "${userApi}"

      #> Extract and update catppuccin flavor, if necessary
      if ${(hasInfix "catppuccin" theme)} && grep -q "catppuccin.*flavor" "${userApi}"; then
        FLAVOR="${
        if hasInfix "frappe" theme || hasInfix "frappé" theme
        then "frappe"
        else if hasInfix "latte" theme
        then "latte"
        else if hasInfix "mocha" theme
        then "mocha"
        else if hasInfix "macchiato" theme
        then "macchiato"
        else if mode == "dark"
        then "frappe"
        else "latte"
      }"
        ${sd} 'flavor = "[^"]*"' 'flavor = "'"$FLAVOR"'"' "${userApi}"
      fi

      #> Update the freedesktop portal setting (what modern apps actually listen to)
      ${dbus} --session --dest=org.freedesktop.portal.Desktop \
        --type=method_call /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.ReadOne \
        string:'org.freedesktop.appearance' string:'color-scheme' \
        uint32:${
        #? 0 = no preference, 1 = prefer dark, 2 = prefer light
        if mode == "dark"
        then "1"
        else "2"
      } || true

      #> Update GTK/Qt theming
      ${dconf} /org/gnome/desktop/interface/color-scheme "'prefer-${mode}'" || true
      ${dconf} /org/gnome/desktop/interface/gtk-theme "'Catppuccin-${
        if mode == "dark"
        then "Frappe"
        else "Latte"
      }'" || true

      #> Update wallpaper
      if [ -L "${oldWallpaper}" ] || [ -e "${newWallpaper}" ]; then
        ${ln} -sf "${newWallpaper}" "${oldWallpaper}"
      fi

      #> Rebuild home-manager only (much faster than full system)
      ${nh} home switch "${dots}" || true

      #> Reload Hyprland
      ${hypr} reload || true

      #> Notify
      ${note} "Theme Switched" "Switched to ${mode} mode - restart apps to see full changes" -t 3000 || true
    '';
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
    darkModeScripts.nixos-theme = mkModeScript "dark";
    lightModeScripts.nixos-theme = mkModeScript "light";
  };
}
