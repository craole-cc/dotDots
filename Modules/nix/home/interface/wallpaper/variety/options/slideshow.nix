{
  lix,
  paths,
  ...
}: let
  inherit (lix.options.construction) mkFalse mkFloatOrStrOption mkStrOption mkTrue;
in {
  slideshow = {
    preferred.enable = mkTrue "Variety slideshow preferred wallpapers enabled";
    sources.enable = mkTrue "Variety slideshow sources enabled.";
    downloads.enable = mkFalse "Variety slideshow downloads enabled.";

    custom = {
      enable = mkFalse "Variety slideshow custom enabled";
      folder = mkStrOption {
        default = paths.wallpapers.slideshow;
        description = "Variety slideshow custom folder.";
      };
    };
    sortOrder = mkStrOption {
      default = "Random";
      description = "Variety slideshow sort order.";
    };
    monitor = mkStrOption {
      default = "All";
      description = "Variety slideshow monitor.";
    };
    mode = mkStrOption {
      default = "Fullscreen";
      description = "Variety slideshow mode.";
    };
    seconds = mkFloatOrStrOption {
      default = 6.0;
      description = "Variety slideshow seconds.";
    };
    fade = mkFloatOrStrOption {
      default = 0.4;
      description = "Variety slideshow fade.";
    };
    zoom = mkFloatOrStrOption {
      default = 0.2;
      description = "Variety slideshow zoom.";
    };
    pan = mkFloatOrStrOption {
      default = 0.05;
      description = "Variety slideshow pan.";
    };
  };
}
