{
  lib,
  pkgs,
  ...
}:
let
  polarity = "dark";

  scheme = {
    dark = mkTheme "bluloco-dark";
    light = mkTheme "bluloco-light";
  };

  wallpaper = {
    light = mkWallpaper {
      url = "https://getwallpapers.com/wallpaper/full/a/5/0/164628.jpg";
      hash = "sha256-OYiNOlX68GYQTiZPh7PR1J9JxF5zsI7UbPeV1pmHEp8=";
    };
    dark = mkWallpaper {
      url = "https://getwallpapers.com/wallpaper/full/9/3/d/534150.jpg";
      hash = "sha256-DNS6Z5msFoGYW2KgTXAGDi/+MomduPktJZq0y13asLs=";
    };
  };

  inherit (lib.modules) mkForce;

  mkStylix =
    variant: overrides:
    overrides
    // {
      image = wallpaper.${variant};
      base16Scheme = scheme.${variant};
      polarity = variant;
    };

  mkWallpaper =
    {
      url,
      hash ? "",
    }:
    pkgs.fetchurl { inherit url hash; };

  # themes = "${pkgs.base16-schemes}/share/themes";
  themes = ../../../assets/themes;
  mkTheme = variant: themes + "/${variant}.yaml";
in
{
  stylix = mkStylix polarity { };

  specialisation = {
    light.configuration = {
      stylix = mkForce (mkStylix "light" { });
      system.copySystemConfiguration = mkForce false;
    };

    dark.configuration = {
      stylix = mkForce (mkStylix "dark" { });
      system.copySystemConfiguration = mkForce false;
    };
  };
}
