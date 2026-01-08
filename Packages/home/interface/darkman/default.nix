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
  inherit (lib.strings) hasPrefix hasInfix optionalString toLower;
  inherit (pkgs) writeShellScript;

  #~@ Location
  loc = user.localization or host.localization or nixosConfig.location or {};
  lat = loc.latitude or null;
  lng = loc.longitude or null;
  usegeoclue = (loc.provider or "manual") == "geoclue2";

  #~@ Style
  style = user.interface.style or host.interface.style or {};
  switch = style.autoSwitch or false;

  #~@ Check if user is using catppuccin
  isCatppuccin = mode: let
    theme = toLower (style.theme.${mode} or "");
  in
    hasInfix "catppuccin" theme;

  #~@ Extract catppuccin flavor from theme string
  getCatppuccinFlavor = mode: let
    theme = toLower (style.theme.${mode} or "");
  in
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
    else "latte";

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

  #~@ Mode script generator# Packages/home/common/darkman.nix
  mkModeScript = mode: let
    sd = "${pkgs.sd}/bin/sd";
    ln = "${pkgs.coreutils}/bin/ln";
    hyprctl = "${pkgs.hyprland}/bin/hyprctl";

    modeWallpaper = "${wallpapers}/${mode}-wallpaper";
    currentWallpaper = "${wallpapers}/current-wallpaper";

    catppuccinUpdates = optionalString (isCatppuccin mode) ''
      #> Update catppuccin flavor in user configuration
      FLAVOR="${getCatppuccinFlavor mode}"
      if grep -q "catppuccin.*flavor" "${userApi}"; then
        ${sd} 'flavor = "[^"]*"' 'flavor = "'"$FLAVOR"'"' "${userApi}"
      fi
    '';
  in
    writeShellScript "darkman-${mode}-mode" ''
      set -euo pipefail

      #> Update theme mode in user configuration
      ${sd} 'current = "(dark|light)"' 'current = "${mode}"' "${userApi}"

      ${catppuccinUpdates}

      #> Update wallpaper and reload Hyprland
      if [ -L "${currentWallpaper}" ] || [ -e "${modeWallpaper}" ]; then
        ${ln} -sf "${modeWallpaper}" "${currentWallpaper}"
        # Set wallpaper in Hyprland immediately
        ${hyprctl} hyprpaper wallpaper ",${currentWallpaper}" || true
      fi

      #> Update Foot terminal config in real-time
      FOOT_CONFIG="$HOME/.config/foot/foot.ini"
      if [ -f "$FOOT_CONFIG" ]; then
        ${sd} 'theme=Catppuccin-.+' 'theme=Catppuccin-${
        if mode == "dark"
        then "Frappe"
        else "Latte"
      }' "$FOOT_CONFIG"
      fi

      #> Reload GTK theme
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-${mode}'" || true

      #> Reload Hyprland config
      ${hyprctl} reload || true

      #> Notify about the change
      ${pkgs.libnotify}/bin/notify-send "Theme Switched" "Changed to ${mode} mode" -t 2000 || true

      #> Optional: Rebuild in background for persistent changes
      # (${pkgs.nh}/bin/nh home switch "${dots}" &) || true
    '';
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
    darkModeScripts.nixos-theme = mkModeScript "dark";
    lightModeScripts.nixos-theme = mkModeScript "light";
  };
}
