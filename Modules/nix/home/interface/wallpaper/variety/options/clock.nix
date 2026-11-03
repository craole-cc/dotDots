{
  lix,
  fonts,
  ...
}: let
  inherit (lix.lists.access) head;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.options.construction) mkOption mkStrOption mkTrue;
  inherit (lix.strings.construction) concat;
  inherit (lix.content.emptiness) isNotEmpty;
  inherit (lix.types.primitives) str;

  mkFont = {
    kind ? "display",
    size ? null,
    fallback ? "sansSerif",
  }: let
    default = {
      family = "monospace";
      size = "28";
    };
    category =
      if (isNotEmpty kind)
      then kind
      else fallback;
    font = head ((fonts.categories.${category} or []) ++ [default]);
  in
    concat " " [
      font.family
      (toString (
        if isNotEmpty size
        then size
        else font.size
      ))
    ];

  mkFontOption = {
    name,
    size ? null,
    kind ? null,
    fallback ? null,
  }:
    mkStrOption {
      description = "Font family and size used to display the ${name} on the wallpaper.";
      default = mkFont (
        filterAttrs (_: arg: arg != null) {inherit size kind fallback;}
      );
    };
in {
  clock = {
    enable = mkTrue "Display the current time on the wallpaper";
    font = mkFontOption {name = "time";};

    date = {
      enable = mkTrue "Display the date alongside the clock on the wallpaper";
      font = mkFontOption {
        name = "date";
        size = 32;
      };
    };

    filter = mkOption {
      type = str;
      description = "ImageMagick arguments that draw the clock.";
      default = ''-density 100 -font `fc-match -f '%{file[0]}' '%CLOCK_FONT_NAME'` -pointsize %CLOCK_FONT_SIZE -gravity SouthEast -fill '#00000044' -annotate 0x0+[%HOFFSET+58]+[%VOFFSET+108] '%H:%M' -fill white -annotate 0x0+[%HOFFSET+60]+[%VOFFSET+110] '%H:%M' -font `fc-match -f '%{file[0]}' '%DATE_FONT_NAME'` -pointsize %DATE_FONT_SIZE -fill '#00000044' -annotate 0x0+[%HOFFSET+58]+[%VOFFSET+58] '%A, %B %d' -fill white -annotate 0x0+[%HOFFSET+60]+[%VOFFSET+60] '%A, %B %d' '';
    };
  };
}
