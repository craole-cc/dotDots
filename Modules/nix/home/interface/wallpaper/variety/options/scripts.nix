{lix, ...}: let
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.combinators) nullOr oneOf;
  inherit (lix.types.primitives) path str;
in {
  scripts = mapAttrs (_name: description:
    mkOption {
      type = nullOr (oneOf [path str]);
      default = null;
      inherit description;
    }) {
    set = "Custom executable path for setting wallpaper. Receives Variety's arguments unchanged, with the image path first. Null uses the selected backend.";
    set-lockscreen = "Custom executable path for setting the lock screen. Receives image, change reason, original image and mode. Null uses varietyctl set-lockscreen.";
    get = "Custom executable path for reading wallpaper. Must print the current image path to stdout. Null uses the selected backend.";
  };
}
