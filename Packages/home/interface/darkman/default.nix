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

  #~@ Mode script generator
  mkModeScript = mode: let
    sd = "${pkgs.sd}/bin/sd";
    ln = "${pkgs.coreutils}/bin/ln";

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

      #> Update wallpaper symlink
      if [ -L "${currentWallpaper}" ] || [ -e "${modeWallpaper}" ]; then
        ${ln} -sf "${modeWallpaper}" "${currentWallpaper}"
      fi

      #> Reload GTK theme via dconf
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-${mode}'" || true

      #> Show notification
      ${pkgs.libnotify}/bin/notify-send "Theme Changed" "Switched to ${mode} mode (${getCatppuccinFlavor mode})" || true

      #> Optional: Rebuild in background (comment out if too slow)
      # ${pkgs.nh}/bin/nh os switch "${dots}" &
    '';
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
    darkModeScripts.nixos-theme = mkModeScript "dark";
    lightModeScripts.nixos-theme = mkModeScript "light";
  };
}
