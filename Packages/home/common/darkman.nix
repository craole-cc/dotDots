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

  loc = user.localization or host.localization or nixosConfig.location or  {};
  lat = loc.latitude or null;
  lng = loc.longitude or null;

  style = user.interface.style or host.interface.style or {};
  autoSwitch = style.autoSwitch or false;

  wallpapers = let
    path = user.paths.wallpapers or host.paths.wallpapers or "Pictures/Wallpapers";
  in
    #> Resolve wallpapers path
    if hasPrefix "/" path
    then path
    else config.home.homeDirectory + "/" + path;

  dots = host.paths.dots or null;

  enable = autoSwitch && (lat != null) && (lng != null) && (dots != null);

  mkModeScript = mode:
    writeShellScript "darkman-${mode}-mode" ''
      # Update theme mode in host configuration
      ${pkgs.sd}/bin/sd \
        'current = "(dark|light)"' \
        'current = "${mode}"' \
        ${dots}/API/users/${user.name}/default.nix

      # Update wallpaper symlink before rebuild
      WALLPAPER_DIR="${wallpapers}"
      if [ -L "$WALLPAPER_DIR/current-wallpaper" ] ||
         [ -e "$WALLPAPER_DIR/${mode}-wallpaper" ]
      then
        ln -sf \
          "$WALLPAPER_DIR/${mode}-wallpaper" \
          "$WALLPAPER_DIR/current-wallpaper"
      fi

      # Apply changes
      ${pkgs.nh}/bin/nh os switch ${dots}
    '';
in {
  services.darkman = mkIf enable {
    inherit enable;

    settings = {
      inherit lat lng;
      usegeoclue = (loc.provider or "manual") == "geoclue2";
    };

    darkModeScripts.nixos-theme = mkModeScript "dark";
    lightModeScripts.nixos-theme = mkModeScript "light";
  };
}
