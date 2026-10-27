{
  lix,
  fonts,
  ...
}: let
  inherit (lix.lists.access) head;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.primitives) bool str;
  display = fonts.categories.display;
  monospace = fonts.categories.monospace;
  displayFont = if display == [] then "" else (head display).family;
  monospaceFont = if monospace == [] then "" else (head monospace).family;
in {
  clock = {
    enable = mkOption {
      type = bool;
      default = true;
    };
    font = mkOption {
      type = str;
      default = "${displayFont} 70";
    };
    dateFont = mkOption {
      type = str;
      default = "${monospaceFont} 30";
    };
    filter = mkOption {
      type = str;
      description = "ImageMagick arguments that draw the clock.";
      default = ''-density 100 -font `fc-match -f '%{file[0]}' '%CLOCK_FONT_NAME'` -pointsize %CLOCK_FONT_SIZE -gravity SouthEast -fill '#00000044' -annotate 0x0+[%HOFFSET+58]+[%VOFFSET+108] '%H:%M' -fill white -annotate 0x0+[%HOFFSET+60]+[%VOFFSET+110] '%H:%M' -font `fc-match -f '%{file[0]}' '%DATE_FONT_NAME'` -pointsize %DATE_FONT_SIZE -fill '#00000044' -annotate 0x0+[%HOFFSET+58]+[%VOFFSET+58] '%A, %B %d' -fill white -annotate 0x0+[%HOFFSET+60]+[%VOFFSET+60] '%A, %B %d' '';
    };
  };
}
