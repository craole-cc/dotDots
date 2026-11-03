{pkgs, ...}: {
  plugins = {
    wallpaperDiscovery.enable = true;
    wallpaperCarousel.enable = true;
    spotlightWallpapers.enable = true;
  };

  packages = with pkgs; [curl];
}
